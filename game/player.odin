package game

import "core:fmt"
import l "core:math/linalg"
import rl "vendor:raylib"

PLAYER_MOVESPEED :: 100
PLAYER_ROLL_DISTANCE :: 100

Player :: struct {
	state:                  PlayerState,
	translation:            Vec2,
	velocity:               Vec2,
	using attributes:       PlayerAttributes,
	animation_player:       AnimationPlayer,
	player_animation_state: PlayerAnimationState,
}

PlayerAttributes :: struct {
	radius:          f32,
	dodge_cooldown:  f32,
	shot_amount:     int,
	shot_iterations: int,
	shot_spread:     f32,
	shot_speed:      f32,
	shot_type:       ShotType,
}

PlayerState :: union {
	PlayerMoving,
	PlayerDodging,
}
PlayerAnimationState :: enum {
	Idle,
	Moving,
}

PlayerMoving :: struct {}
PlayerDodging :: struct {
	target:   Vec2,
	duration: f32,
	progress: f32,
}

Character_Tag :: enum {
	MiniNobleWoman,
}

character_sheet: rl.Texture

make_player :: proc() -> Player {
	chosen_character: Character_Tag = .MiniNobleWoman
	attributes := PlayerAttributes {
		radius          = 8,
		shot_type       = .Normal,
		shot_amount     = 1,
		shot_iterations = 1,
		shot_speed      = 100,
		shot_spread     = 22.5,
	}
	append(&player_attributes, attributes)
	return Player {
		radius = 8,
		shot_type = .Normal,
		state = PlayerMoving{},
		shot_amount = 1,
		shot_iterations = 1,
		shot_speed = 100,
		shot_spread = 22.5,
		animation_player = AnimationPlayer {
			frame_length = 0.1,
			texture = &character_texture_atlas[chosen_character],
			current_animation = character_animations[chosen_character][.Idle],
			current_frame = character_animations[chosen_character][.Idle].start,
		},
	}
}

render_players :: proc() {
	player := world.player
	color := rl.BLUE

	relative_position := get_relative_position(player.translation)
	current_frame := player.animation_player.current_frame
	x_position := f32(current_frame % 6) * 32
	y_position := f32(current_frame / 6) * 32

	source_rect := rl.Rectangle {
		x      = x_position,
		y      = y_position,
		width  = 32,
		height = 32,
	}

	rl.DrawTextureRec(player.animation_player.texture^, source_rect, relative_position, rl.WHITE)
}

player_shoot :: proc() {
	player := &world.player
	input := world.current_input_tick
	translation := player.translation + Vec2{f32(TILE_SIZE) / 2, f32(TILE_SIZE) / 2}
	if .Shoot in input.buttons {
		spawner: BulletSpawner
		switch player.shot_type {
		case .Normal:
			spawner = make_arc_spawner(
				tag = .Player,
				source = translation,
				shot_count = player.shot_amount,
				wave_count = player.shot_iterations,
				distance = 8,
				shot_cooldown = 0.05,
				angle = input.mouse_rotation,
				arc = player.shot_spread,
				speed = player.shot_speed,
			)
		case .Spiral:
			spawner = make_circle_spawner(
				tag = .Player,
				source = translation,
				shot_count = player.shot_amount,
				wave_count = player.shot_iterations,
				distance = 8,
				shot_cooldown = 0.05,
				rotation_speed = 360,
				travel_speed = 75,
			)
		case .Orbital:
			spawner = make_orbital_spawner(
				tag = .Player,
				source = translation,
				shot_count = player.shot_amount,
				wave_count = player.shot_iterations,
				distance = 8,
				shot_cooldown = 0.05,
				angle = input.mouse_rotation,
				speed = 100,
				radius = 10,
				rotation_speed = 720,
			)
		}

		append(&bullet_spawners, spawner)
	}
}

player_dodge :: proc() {
	player := &world.player
	input := world.current_input_tick
	should_dodge := .Roll in input.buttons
	direction := direction_to_vec(input.direction)

	if player.dodge_cooldown > 0 {
		player.dodge_cooldown = clamp(player.dodge_cooldown - TICK_RATE, 0, player.dodge_cooldown)
	}

	if player.dodge_cooldown == 0 && should_dodge && input.direction != .Neutral {
		player.state = PlayerDodging {
			target   = player.translation + (direction * PLAYER_ROLL_DISTANCE),
			duration = 0.2,
		}
		player.dodge_cooldown = 1
	}

	anim := &player.animation_player
	anim.animation_progression += TICK_RATE
	if anim.animation_progression > anim.frame_length {
		anim.animation_progression = 0
		new_frame := anim.current_frame + 1
		if new_frame > anim.current_animation.end {
			new_frame = anim.current_animation.start
		}
		anim.current_frame = new_frame
	}
}

set_player_velocities :: proc() {
	player := &world.player
	input := world.current_input_tick
	new_velo := direction_to_vec(input.direction)
	player.velocity = new_velo * PLAYER_MOVESPEED
}

apply_player_velocities :: proc() {
	player := &world.player
	switch &state in player.state {
	case PlayerMoving:
		player.translation += player.velocity * TICK_RATE
	case PlayerDodging:
		state.progress += TICK_RATE
		amount := clamp(state.progress / state.duration, 0, 1.0)
		player.translation = l.lerp(player.translation, state.target, amount)
		if state.progress > state.duration {
			player.state = PlayerMoving{}
		}
	}
}

spawn_player :: proc(player: ^Player, level: Level) {
	player.translation = get_spawn_point(level)
}

kill_player :: proc(world: ^World) {
	level := world.levels[world.current_level]
	world.current_level = .Hub
	level = world.levels[world.current_level]
	spawn_player(&world.player, level)
	reset_loop()
}

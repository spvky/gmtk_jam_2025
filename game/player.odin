package game

import "core:fmt"
import "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"

PLAYER_MOVESPEED :: 100
PLAYER_ROLL_DISTANCE :: 100
PLAYER_HEALTH :: 3

Player :: struct {
	state:                  PlayerState,
	translation:            Vec2,
	velocity:               Vec2,
	animation_player:       AnimationPlayer,
	player_animation_state: PlayerAnimationState,
	health:                 u8,
}

PlayerAttributes :: struct {
	damage:          u8,
	radius:          f32,
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
	Dead,
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

chosen_character: Character_Tag
make_player :: proc() -> Player {
	chosen_character = .MiniNobleWoman
	attributes := PlayerAttributes {
		damage          = 5,
		radius          = 8,
		shot_type       = .Normal,
		shot_amount     = 1,
		shot_iterations = 1,
		shot_speed      = 100,
		shot_spread     = 22.5,
	}
	append(&player_attributes, attributes)
	return Player {
		state = PlayerMoving{},
		animation_player = AnimationPlayer {
			frame_length = 0.1,
			texture = &character_texture_atlas[chosen_character],
			current_animation = character_animations[chosen_character][.Idle],
			current_frame = character_animations[chosen_character][.Idle].start,
		},
		health = PLAYER_HEALTH,
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
	attributes := player_attributes[0]
	translation := player.translation + Vec2{f32(TILE_SIZE), f32(TILE_SIZE + 4)}
	if .Shoot in input.buttons {
		spawner: BulletSpawner
		switch attributes.shot_type {
		case .Normal:
			spawner = make_arc_spawner(
				tag = .Player,
				source = translation,
				shot_count = attributes.shot_amount,
				wave_count = attributes.shot_iterations,
				distance = 8,
				shot_cooldown = 0.05,
				angle = input.mouse_rotation,
				arc = attributes.shot_spread,
				speed = attributes.shot_speed,
			)
		case .Spiral:
			spawner = make_circle_spawner(
				tag = .Player,
				source = translation,
				shot_count = attributes.shot_amount,
				wave_count = attributes.shot_iterations,
				distance = 8,
				shot_cooldown = 0.05,
				rotation_speed = 360,
				travel_speed = 75,
			)
		case .Orbital:
			spawner = make_orbital_spawner(
				tag = .Player,
				source = translation,
				shot_count = attributes.shot_amount,
				wave_count = attributes.shot_iterations,
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

set_player_velocities :: proc() {
	player := &world.player
	input := world.current_input_tick
	player.velocity = input.direction
}

apply_player_velocities :: proc() {
	player := &world.player
	switch &state in player.state {
	case PlayerMoving:
		player.translation += player.velocity
	case PlayerDodging:
		state.progress += TICK_RATE
		amount := clamp(state.progress / state.duration, 0, 1.0)
		player.translation = l.lerp(player.translation, state.target, amount)
		if state.progress > state.duration {
			player.state = PlayerMoving{}
		}
	}
}

kill_player :: proc() {
	clear_dynamic_collections()
	world.current_level = .Hub
	world.player.translation = current_spawn_point()
	world.player.health = PLAYER_HEALTH

	world.player.player_animation_state = .Idle
	world.player.animation_player.current_animation = character_animations[chosen_character][.Idle]

	hard_reset_loop()
}

player_wins_wave :: proc() {
	attributes := player_attributes[0]
	inject_at(&player_attributes, 0, attributes)
	clear_dynamic_collections()
	world.current_level = .Hub
	world.player.translation = current_spawn_point()
	world.player.health = PLAYER_HEALTH
	reset_loop()
	make_upgrades()
}

player_animations :: proc() {
	player := &world.player
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

check_player_health :: proc() {
	if world.player.player_animation_state == .Dead &&
	   world.player.animation_player.current_frame == world.player.animation_player.current_animation.end {
		kill_player()
		return

	} else if world.player.health == 0 {
		if world.player.player_animation_state != .Dead {

			world.player.player_animation_state = .Dead
			world.player.animation_player.current_animation = character_animations[chosen_character][.Dead]
			world.player.animation_player.current_frame = world.player.animation_player.current_animation.start
		} else {
			vignette_radius_uv_space -= 0.01
		}
	}
}

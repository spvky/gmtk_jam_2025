package game

import "core:fmt"
import "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"

Enemy :: struct {
	tag:              EnemyTag,
	animation_player: AnimationPlayer,
	position:         rl.Vector2,
	direction:        rl.Vector2,
	state:            EnemyState,
	prev_state:       EnemyState,
	spawned_tick:     u16,
	damaged_timer:    f32,
	health:           u8,
}

ENEMY_DAMAGE_TIME :: 0.3
SKELETON_ATTACK_RANGE_RADIUS_PX :: 8
VAMPIRE_ATTACK_RANGE_RADIUS_PX :: 120

MARCHING_STEPS :: 20

EnemyTag :: enum {
	Skeleton,
	Vampire,
}

enemy_attack_frame_from_tag :: proc(tag: EnemyTag) -> int {
	frame: int
	switch tag {
	case .Skeleton:
		frame = 24
	case .Vampire:
		frame = 38
	}
	return frame
}

EnemyState :: enum {
	Spawning,
	Idle,
	Movement,
	Attack,
	Die,
}

make_enemy :: proc(tag: EnemyTag, position: Vec2) -> Enemy {
	enemy: Enemy
	health_val: u8

	switch tag {
	case .Skeleton:
		health_val = 12
	case .Vampire:
		health_val = 8
	}

	return Enemy {
		tag = tag,
		animation_player = AnimationPlayer {
			frame_length = 0.1,
			texture = &enemy_texture_atlas[tag],
			current_animation = enemy_animations[tag][.Idle],
			current_frame = enemy_animations[tag][.Idle].start,
		},
		prev_state = .Idle,
		state = .Spawning,
		position = position,
		spawned_tick = world.current_tick,
		health = health_val,
	}
}

enemy_transition_state :: proc() {
	for &enemy in enemies {
		if enemy.prev_state != enemy.state {
			new_anim := enemy_animations[enemy.tag][enemy.state]
			enemy.animation_player.animation_progression = 0
			enemy.animation_player.current_frame = new_anim.start
			enemy.animation_player.current_animation = new_anim
		}
		enemy.prev_state = enemy.state
	}
}

raymarch :: proc(start: Vec2, end: Vec2) -> bool {
	level := world.levels[world.current_level]
	for i in 0 ..< MARCHING_STEPS {
		distance := (end - start) * (f32(i) / f32(MARCHING_STEPS))
		for tile in level.tiles {
			if .Collision in tile.properties {
				tile_rect: rl.Rectangle = {
					x      = tile.position.x + TILE_SIZE,
					y      = tile.position.y + TILE_SIZE,
					width  = TILE_SIZE,
					height = TILE_SIZE,
				}
				if rl.CheckCollisionPointRec(start + distance, tile_rect) {
					return true
				}
			}
		}
	}

	return false
}

should_enemy_be_attacking :: proc(enemy: Enemy) -> bool {
	switch enemy.tag {
	case .Skeleton:
		return l.distance(enemy.position, world.player.translation) < SKELETON_ATTACK_RANGE_RADIUS_PX
	case .Vampire:
		if l.distance(enemy.position, world.player.translation) < VAMPIRE_ATTACK_RANGE_RADIUS_PX {
			return !raymarch(enemy.position, world.player.translation)
		}
	}
	return false
}

update_enemies :: proc(flow_field: [][]rl.Vector2) {
	for &enemy, i in enemies {
		if enemy.damaged_timer > 0 {
			enemy.damaged_timer = math.clamp(enemy.damaged_timer - TICK_RATE, 0, ENEMY_DAMAGE_TIME)
		}
		animate_enemy(&enemy)

		if enemy.health == 0 {
			enemy.state = .Die
		}

		switch enemy.state {
		case .Spawning:
			if enemy.animation_player.current_frame == enemy.animation_player.current_animation.end {
				enemy.state = .Movement
			}

			continue
		case .Idle:
			if should_enemy_be_attacking(enemy) {
				enemy.state = .Attack
			}
		case .Movement:
			if should_enemy_be_attacking(enemy) {
				enemy.state = .Attack
			}

			grid_position := ((enemy.position - world.levels[world.current_level].position) / TILE_SIZE)

			grid_source_pos: [2]int = {int(math.floor(grid_position.x)), int(math.floor(grid_position.y))}
			// if we are moving upwards we want to wait until we are 'leaving' the square
			// until we source the new flow field instruction
			// otherwise, we get weird behaviour because as we barely cross the coordinate border from 1.0 to 0.99
			// we will now use the instruction at 0. instead of 1, despite us being at the top part of 1, moving up towards 0.

			if enemy.direction.x < 0 {
				grid_source_pos.x = int(math.ceil(grid_position.x))
			}
			if enemy.direction.y < 0 {
				grid_source_pos.y = int(math.ceil(grid_position.y))
			}
			direction := flow_field[grid_source_pos.y][grid_source_pos.x]
			enemy.position += direction
			enemy.direction = direction

		case .Attack:
			if enemy.animation_player.current_frame == enemy.animation_player.current_animation.end {
				enemy.state = .Movement
			}
		case .Die:
			if enemy.animation_player.current_frame == enemy.animation_player.current_animation.end {
				unordered_remove(&enemies, i)
			}
		}
	}
}

animate_enemy :: proc(enemy: ^Enemy) {
	anim := &enemy.animation_player

	anim.animation_progression += TICK_RATE
	if anim.animation_progression > anim.frame_length {
		attack_frame := enemy_attack_frame_from_tag(enemy.tag)
		anim.animation_progression = 0
		new_frame := anim.current_frame + 1
		if new_frame > anim.current_animation.end {
			new_frame = anim.current_animation.start
		}

		anim.current_frame = new_frame
		if new_frame == attack_frame && anim.animation_progression == 0 {
			enemy_attack(enemy)
		}
	}
}

enemy_attack :: proc(enemy: ^Enemy) {
	switch enemy.tag {
	case .Skeleton:
	case .Vampire:
		spawner := make_circle_spawner(.Enemy, enemy.position, 4, 2, 5, 0.15, 45, 100)
		append(&bullet_spawners, spawner)
	}
}

draw_enemies :: proc() {
	for enemy in enemies {
		relative_position := get_relative_position(enemy.position)
		current_frame := enemy.animation_player.current_frame
		x_position := f32(current_frame % 9) * 32
		y_position := f32(current_frame / 9) * 32
		source_rect := rl.Rectangle {
			x      = x_position,
			y      = y_position,
			width  = 32,
			height = 32,
		}
		// debug
		// rl.DrawLineV(relative_position, relative_position + enemy.direction * 16, rl.GREEN)
		// we are correctly computing the position for the enemies, but because the sprite sizes are not what we anticipate the dimenions here are iffy and we end up drawing from 1 tile^2 to the topleft.
		// but you can uncomment the debug drawing to validate

		// drawing debug rectangle for the the where we compute their position from
		// rl.DrawRectangleV(relative_position, {16, 16}, rl.WHITE)

		// drawing sprite at an odd offset to align the sprite with where they are in the world
		red := [4]f32{230, 41, 55, 255}
		white := [4]f32{255, 255, 255, 255}
		color := math.lerp(white, red, enemy.damaged_timer / ENEMY_DAMAGE_TIME)
		rl.DrawTextureRec(
			enemy.animation_player.texture^,
			source_rect,
			relative_position - {4, 12},
			rl.Color{u8(color.r), u8(color.g), u8(color.b), u8(color.a)},
		)
	}
}

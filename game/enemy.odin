package game

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Enemy :: struct {
	tag:              EnemyTag,
	animation_player: AnimationPlayer,
	position:         rl.Vector2,
	direction:        rl.Vector2,
	state:            EnemyState,
	prev_state:       EnemyState,
}

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
	Idle,
	Movement,
	Attack,
	Die,
}

make_enemy :: proc(tag: EnemyTag, position: Vec2) -> Enemy {
	enemy: Enemy

	return Enemy {
		tag = tag,
		animation_player = AnimationPlayer {
			frame_length = 0.1,
			texture = &enemy_texture_atlas[tag],
			current_animation = enemy_animations[tag][.Idle],
			current_frame = enemy_animations[tag][.Idle].start,
		},
		state = .Attack,
		position = position,
	}
}

enemy_transition_state :: proc() {
	for &enemy in enemies {
		if enemy.prev_state != enemy.state {

		}
		enemy.prev_state = enemy.state
	}
}

update_enemies :: proc(flow_field: [][]rl.Vector2) {
	for &enemy in enemies {
		grid_position := (enemy.position / TILE_SIZE)

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
		animate_enemy(&enemy)
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
		if new_frame == attack_frame {
			enemy_attack(enemy)
		}
	}
}

enemy_attack :: proc(enemy: ^Enemy) {
	switch enemy.tag {
	case .Skeleton:
	case .Vampire:
		spawner := make_circle_spawner(.Enemy, enemy.position, 4, 2, 20, 0.25, 45, 100)
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
		rl.DrawTextureRec(enemy.animation_player.texture^, source_rect, relative_position - {4, 12}, rl.WHITE)
	}
}

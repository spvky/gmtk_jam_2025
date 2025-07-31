package game

import "core:fmt"
import rl "vendor:raylib"

Enemy :: struct {
	tag:              EnemyTag,
	animation_player: AnimationPlayer,
	position:         rl.Vector2,
}

EnemyTag :: enum {
	Skeleton,
	Vampire,
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
		position = position,
	}

	// 	switch tag {
	// 	case .Skeleton:
	// 		enemy = {
	// 			tag = .Skeleton,
	// 			animation_player = AnimationPlayer {
	// 				frame_length = 0.1,
	// 				texture = &texture_atlas[.Skeleton],
	// 				current_animation = skeleton_animations[.Idle],
	// 				current_frame = skeleton_animations[.Idle].start,
	// 			},
	// 			position = position,
	// 		}
	// 	case .Vampire:
	// 		enemy = {
	// 			tag = .Vampire,
	// 			animation_player = AnimationPlayer {
	// 				frame_length = 0.1,
	// 				texture = &texture_atlas[.Vampire],
	// 				current_animation = skeleton_animations[.Idle],
	// 				current_frame = skeleton_animations[.Idle].start,
	// 			},
	// 			position = position,
	// 		}
	// 	}
	// 	return enemy
}

update_enemies :: proc(flow_field: [][]rl.Vector2) {
	for &enemy in enemies {
		grid_position := (enemy.position / TILE_SIZE)
		direction := flow_field[int(grid_position.y)][int(grid_position.x)]
		enemy.position += direction
		animate_enemy(&enemy)
	}
}

animate_enemy :: proc(enemy: ^Enemy) {
	anim := &enemy.animation_player

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
		rl.DrawTextureRec(enemy.animation_player.texture^, source_rect, relative_position, rl.WHITE)
	}
}

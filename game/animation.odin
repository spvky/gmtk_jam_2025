package game

import rl "vendor:raylib"

AnimationPlayer :: struct {
	frame_length:          f32,
	texture:               ^rl.Texture,
	current_animation:     Animation,
	current_frame:         int,
	animation_progression: f32,
}

Animation :: struct {
	start: int,
	end:   int,
}

enemy_animations := [EnemyTag][EnemyState]Animation {
	.Skeleton = {
		.Idle = {start = 0, end = 5},
		.Movement = {start = 6, end = 15},
		.Attack = {start = 18, end = 26},
		.Die = {start = 27, end = 43},
	},
	.Vampire = {
		.Idle = {start = 0, end = 5},
		.Movement = {start = 6, end = 13},
		.Attack = {start = 28, end = 26},
		.Die = {start = 14, end = 43},
	},
}

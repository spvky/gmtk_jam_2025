package game

import rl "vendor:raylib"

skeleton_animations := [SkeletonAnimation]Animation {
	.Idle = {start = 0, end = 5},
	.Movement = {start = 6, end = 15},
	.Attack = {start = 18, end = 26},
	.Die = {start = 27, end = 43},
}

AnimationPlayer :: struct {
	frame_length:      f32,
	texture:           ^rl.Texture,
	current_animation: Animation,
	current_index:     int,
}

Animation :: struct {
	start: int,
	end:   int,
}

// Skeleton
SkeletonAnimation :: enum {
	Idle,
	Movement,
	Attack,
	Die,
}

animate_enemies :: proc()

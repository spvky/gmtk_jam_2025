package game

import "core:math"
import rl "vendor:raylib"


Button :: enum u8 {
	Shoot,
	Roll,
}

Direction :: enum u8 {
	Neutral,
	Up,
	Down,
	Left,
	Right,
	UpLeft,
	UpRight,
	DownLeft,
	DownRight,
}

direction_to_vec :: proc(dir: Direction) -> Vec2 {
	vec: Vec2
	#partial switch dir {
	case .Up:
		vec = {0, -1}
	case .Down:
		vec = {0, 1}
	case .Left:
		vec = {-1, 0}
	case .Right:
		vec = {1, 0}
	case .UpLeft:
		vec = {-0.707, -0.707}
	case .UpRight:
		vec = {0.707, -0.707}
	case .DownLeft:
		vec = {-0.707, 0.707}
	case .DownRight:
		vec = {0.707, 0.707}
	}
	return vec
}

InputStream :: [10_000]InputTick


InputTick :: struct {
	direction:      Direction,
	buttons:        bit_set[Button],
	mouse_rotation: f32,
}

InputMode :: enum {
	Live,
	Playback,
}

get_mouse_rotation :: proc(relative_position: rl.Vector2) -> f32 {
	normalized_mouse_position := rl.GetMousePosition() / {f32(WINDOW_WIDTH), f32(WINDOW_HEIGHT)}

	screen_space_mouse_position := normalized_mouse_position * {SCREEN_WIDTH, SCREEN_HEIGHT}

	offset := screen_space_mouse_position - relative_position

	return math.atan2(offset.y, offset.x)

}


read_input :: proc(mouse_rotation: f32) {
	x, y: i8
	direction := Direction.Neutral
	if rl.IsKeyDown(.A) {
		x -= 1
	}
	if rl.IsKeyDown(.D) {
		x += 1
	}
	if rl.IsKeyDown(.S) {
		y += 1
	}
	if rl.IsKeyDown(.W) {
		y -= 1
	}

	switch true {
	case x == -1 && y == 0:
		direction = .Left
	case x == 1 && y == 0:
		direction = .Right
	case x == 0 && y == 1:
		direction = .Down
	case x == 0 && y == -1:
		direction = .Up
	case x == -1 && y == -1:
		direction = .UpLeft
	case x == 1 && y == -1:
		direction = .UpRight
	case x == -1 && y == 1:
		direction = .DownLeft
	case x == 1 && y == 1:
		direction = .DownRight
	}

	buttons: bit_set[Button]

	if rl.IsKeyDown(.SPACE) {
		buttons = buttons | {.Shoot}
	}
	if rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT) {
		buttons = buttons | {.Roll}
	}

	world.current_input_tick = InputTick {
		direction      = direction,
		buttons        = buttons,
		mouse_rotation = mouse_rotation,
	}

}

write_input_to_stream :: proc() {
	input_streams[0][world.current_tick] = world.current_input_tick
}

make_input_streams :: proc() -> [dynamic]InputStream {
	return make([dynamic]InputStream, 1, 8)
}

destroy_input_streams :: proc() {
	delete(input_streams)
}

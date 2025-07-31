package game

import rl "vendor:raylib"


Button :: enum u8 {
	Action,
	Hands,
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

InputStream :: [30_000]InputTick


InputTick :: struct {
	direction: Direction,
	buttons:   bit_set[Button],
}

InputMode :: enum {
	Live,
	Playback,
}

read_input :: proc() {
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
		buttons = buttons | {.Action}
	}
	if rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT) {
		buttons = buttons | {.Hands}
	}

	world.current_input_tick = InputTick {
		direction = direction,
		buttons   = buttons,
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

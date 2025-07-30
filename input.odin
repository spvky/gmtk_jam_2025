package main

Button :: enum { A,B,C }
Direction :: enum u8 {
	Neutral,
	Up,
	Down,
	Left,
	Right,
	UpLeft,
	UpRight,
	DownLeft,
	DownRight
}

InputStream :: [60_000]InputEvent


InputEvent :: struct {
	direction: Direction,
	buttons: bit_set[Button],
}

InputMode :: enum {
	Live,
	Playback
}

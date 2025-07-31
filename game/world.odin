package game

World :: struct {
	loop_number:        u8,
	current_tick:       u16,
	game_state:         GameState,
	current_input_tick: InputTick,
	players:            Player,
}

GameState :: enum {
	Playing,
	MainMenu,
	Paused,
	Looping,
}

make_world :: proc() -> World {
	return World{}
}

destroy_world :: proc() {
}

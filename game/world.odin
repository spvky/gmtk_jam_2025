package game

World :: struct {
	loop_number:        u8,
	current_tick:       u16,
	loop_time:					f32,
	simulation_time:		f32,
	game_state:         GameState,
	current_input_tick: InputTick,
	loop_timer_started: bool,
	player:             Player,
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

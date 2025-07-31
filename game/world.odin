package game

World :: struct {
	loop_number:        u8,
	current_tick:       u16,
	loop_time:          f32,
	simulation_time:    f32,
	game_state:         GameState,
	current_input_tick: InputTick,
	loop_timer_started: bool,
	player:             Player,
	levels:             [dynamic]Level,
	current_level:      Level_Enum,
}

GameState :: enum {
	Playing,
	MainMenu,
	Paused,
	Looping,
}

make_world :: proc() -> World {
	return World{player = make_player()}
}

destroy_world :: proc() {
}

package game

World :: struct {
	loop_number:        u8,
	current_tick:       u16,
	simulation_time:    f32,
	game_state:         GameState,
	current_input_tick: InputTick,
	player:             Player,
	levels:             [dynamic]Level,
	current_level:      Level_Enum,
	first_loop_started: bool,
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

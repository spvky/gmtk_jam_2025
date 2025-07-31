package main

World :: struct {
	loop_number:        u8,
	current_tick:       u16,
	loop_time:          f32,
	simulation_time:    f32,
	loop_timer_started: bool,
	game_state:         GameState,
	current_input_tick: InputTick,
	players:            [dynamic]Player,
}

GameState :: enum {
	Playing,
	MainMenu,
	Paused,
	Looping,
}

make_world :: proc() -> World {
	players := make([dynamic]Player, 0, 8)
	append(&players, make_player(.Player))
	return World{game_state = .Playing, players = players}
}

destroy_world :: proc() {
	delete(world.players)
}

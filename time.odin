package main

import "core:fmt"

reset_loop :: proc() {
	world.current_tick = 0
	world.loop_number += 1
	world.loop_time = 0
	world.simulation_time = 0
	world.loop_timer_started = false
	world.game_state = .Looping
	// Seperating these to make it simpler to add a transition when resetting, for now it's immediate
	start_new_loop()
}

start_new_loop :: proc() {
	inject_at_elem(&input_streams, 0, InputStream{})
	clear(&world.players)
	for i in 0 ..= world.loop_number {
		if i == 0 {
			append(&world.players, make_player(.Player))
		} else {
			append(&world.players, make_player(.Ghost))
		}
	}
	when ODIN_DEBUG {
		fmt.printfln(
			"Starting new loop: %v\nPlayers: %v\nInput Streams: %v",
			world.current_tick,
			len(world.players),
			len(input_streams),
		)
	}
	world.game_state = .Playing
}

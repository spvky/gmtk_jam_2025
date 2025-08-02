package game

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

display_clock :: proc() {
	time_to_display := 100.0 - f32(world.current_tick) * TICK_RATE
	time_string := fmt.tprintf("%3.2f", time_to_display)
	rl.DrawText(strings.clone_to_cstring(time_string), 375, 10, 24, rl.WHITE)
}

reset_loop :: proc() {
	world.current_tick = 0
	world.loop_number += 1
	world.simulation_time = 0
	world.game_state = .Looping
	// Seperating these to make it simpler to add a transition when resetting, for now it's immediate
	start_new_loop()
}

start_new_loop :: proc() {
	inject_at_elem(&input_streams, 0, InputStream{})
	for i in 0 ..= world.loop_number {
	}
	when ODIN_DEBUG {
		fmt.printfln(
			"Starting new loop: %v\nPlayers: %v\nInput Streams: %v",
			world.current_tick,
			len(world.player),
			len(input_streams),
		)
	}
	world.game_state = .Playing
}

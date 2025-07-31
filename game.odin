package main

import "core:c"
import "core:math"
import rl "vendor:raylib"

world: World
screen_texture: rl.RenderTexture
run: bool
input_streams: [dynamic]InputStream

TICK_RATE :: 1.0 / 100.0
WINDOW_WIDTH: i32
WINDOW_HEIGHT: i32
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450

init :: proc() {
	WINDOW_WIDTH = 1600
	WINDOW_HEIGHT = 900
	run = true
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Game")
	screen_texture = rl.LoadRenderTexture(SCREEN_HEIGHT, SCREEN_HEIGHT)
	world = make_world()
	input_streams = make_input_streams()
}

update :: proc() {
	switch world.game_state {
	case .Playing:
		// Gameplay Code
		if !world.loop_timer_started {
			world.loop_time = f32(rl.GetTime())
			world.loop_timer_started = true
		}
		read_input()
		t1 := f32(rl.GetTime())
		elapsed := math.min(t1 - world.loop_time, 0.25)
		world.loop_time = t1
		world.simulation_time += elapsed
		for world.simulation_time >= TICK_RATE {
			write_input_to_stream()
			physics_step()
			world.current_tick += 1
			world.simulation_time -= TICK_RATE
		}
		if rl.IsKeyPressed(.R) {
			reset_loop()
		}
	case .Paused:
	case .MainMenu:
	case .Looping:
	}
	//Visual Updates
	render_scene()
	draw_to_screen()
}

shutdown :: proc() {
	rl.UnloadRenderTexture(screen_texture)
	rl.CloseWindow()
	destroy_world()
	destroy_input_streams()
}

should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		run = !rl.WindowShouldClose()
	}
	return run
}

parent_window_size_changed :: proc(w, h: int) {
	WINDOW_WIDTH = i32(w)
	WINDOW_HEIGHT = i32(h)
	rl.SetWindowSize(c.int(WINDOW_WIDTH), c.int(WINDOW_WIDTH))
}

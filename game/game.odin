package game

import "core:c"
import "core:math"
import rl "vendor:raylib"

Vec2 :: rl.Vector2

world: World
screen_texture: rl.RenderTexture
input_streams: [dynamic]InputStream

WINDOW_WIDTH: i32
WINDOW_HEIGHT: i32
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450
run := true

init :: proc() {
	WINDOW_WIDTH = 1600
	WINDOW_HEIGHT = 900
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Game")
	screen_texture = rl.LoadRenderTexture(SCREEN_HEIGHT, SCREEN_HEIGHT)
	world = make_world()
	input_streams = make_input_streams()

	rl.SetTargetFPS(60)
}


draw :: proc() {
	rl.BeginTextureMode(screen_texture)
	rl.ClearBackground(rl.BLACK)
	render_players()
	rl.EndTextureMode()


	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	rl.DrawTexturePro(
		screen_texture.texture,
		{0, 0, SCREEN_WIDTH, -SCREEN_HEIGHT},
		{0, 0, f32(WINDOW_WIDTH), f32(WINDOW_HEIGHT)},
		{0, 0},
		0,
		rl.WHITE,
	)
	rl.EndDrawing()
}

update :: proc() {
	switch world.game_state {
	case .Playing:
		// Gameplay Code
		read_input()
		if rl.IsKeyPressed(.R) {
			reset_loop()
		}

		write_input_to_stream()
		physics_step()
		world.current_tick += 1

	case .Paused:
	case .MainMenu:
	case .Looping:
	}
	//Visual Updates
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

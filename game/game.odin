package game

import ldtk "../ldtk"
import "../utils"
import "core:c"
import "core:fmt"
import "core:math"
import "pathfinding"
import rl "vendor:raylib"

Vec2 :: rl.Vector2

world: World
screen_texture: rl.RenderTexture
input_streams: [dynamic]InputStream

TICK_RATE :: 1.0 / 100.0
WINDOW_WIDTH: i32
WINDOW_HEIGHT: i32
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450
run := true

//temp enemy
enemies: [dynamic]Enemy
bullets: [dynamic]Bullet
ghosts: [dynamic]Ghost
bullet_spawners: [dynamic]BulletSpawner

bullet_control := BulletControl {
	bullet_color = {
		.Player = {{118, 136, 169, 255}, {77, 100, 141, 255}, {21, 44, 85, 255}},
		.Enemy = {{255, 170, 170, 255}, {212, 106, 106, 255}, {128, 21, 21, 255}},
		.Ghost = {{0, 0, 0, 255}, {255, 0, 255, 255}, {0, 0, 0, 255}},
	},
}

// temporary debug access

tilesheet: rl.Texture

// TODO move somewhere sensible
cost_map: [][]int
flow_field: [][]rl.Vector2

ghost_shader: rl.Shader

init :: proc() {
	WINDOW_WIDTH = 1600
	WINDOW_HEIGHT = 900
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Game")
	screen_texture = rl.LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT)
	world = make_world()
	enemy_texture_atlas = make_enemy_texture_atlas()
	input_streams = make_input_streams()
	enemies = make([dynamic]Enemy, 0, 32)
	bullets = make([dynamic]Bullet, 0, 128)
	bullet_spawners = make([dynamic]BulletSpawner, 0, 16)

	tilesheet = rl.LoadTexture("assets/asset_pack/character and tileset/Dungeon_Tileset.png")
	if project, ok := ldtk.load_from_file("assets/level.ldtk", context.temp_allocator).?; ok {
		world.levels = get_all_levels(project)
		world.current_level = .Hub
	}

	spawn_player(&world.player, world.levels[world.current_level])
	rl.SetTargetFPS(60)

	ghost_shader = rl.LoadShader(nil, "assets/shaders/ghost.glsl")
	append(&ghosts, Ghost{})

	init_waves()
}


update :: proc() {
	switch world.game_state {
	case .Playing:
		playing()
	case .Paused:
	case .MainMenu:
	case .Looping:
	}
	free_all(context.temp_allocator)
}

draw :: proc() {
	rl.BeginTextureMode(screen_texture)
	rl.ClearBackground(rl.BLACK)
	display_clock()
	draw_tiles(world.levels[world.current_level], tilesheet, .Structure)
	draw_tiles(world.levels[world.current_level], tilesheet, .Decor)
	render_players()
	draw_enemies()
	draw_bullets()
	draw_ghosts()
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

// Gameplay Code
playing :: proc() {
	level: Level = world.levels[world.current_level]
	if !world.loop_timer_started {
		world.loop_time = f32(rl.GetTime())
		world.loop_timer_started = true
	}

	relative_mouse_rotation := get_mouse_rotation(get_relative_position(world.player.translation))
	read_input(relative_mouse_rotation)
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

	input := world.current_input_tick
	player_shoot()

	target_position := world.player.translation - rl.Vector2{f32(SCREEN_WIDTH), f32(SCREEN_HEIGHT)} / 2
	update_camera_position(target_position)

	// these can be update technically only when moving, if we want to limit the calls
	// or / also at only certain intervals if we want
	cells := level.cell_grid

	grid_position := (world.player.translation - level.position) / TILE_SIZE

	cost_map = pathfinding.generate_cost_map(cells, [2]int{int(grid_position.x), int(grid_position.y)})
	flow_field = pathfinding.generate_flow_field(cost_map, cells)

	handle_triggers(&world)
	update_enemies(flow_field)
	enemy_transition_state()


	u_time := f32(rl.GetTime())

	rl.SetShaderValue(ghost_shader, rl.GetShaderLocation(ghost_shader, "u_time"), &u_time, .FLOAT)
	if rl.IsKeyPressed(.END) {
		kill_player(&world)
	}

	if wave, ok := waves[world.loop_number][world.current_tick].?; ok {
		spawn_wave(wave, level)
	}
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

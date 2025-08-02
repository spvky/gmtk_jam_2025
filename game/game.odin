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
player_attributes: [dynamic]PlayerAttributes

TICK_RATE :: 1.0 / 100.0
WINDOW_WIDTH: i32
WINDOW_HEIGHT: i32
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450
TIME_LIMIT :: 10000
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
	character_texture_atlas = make_character_texture_atlas()
	input_streams = make_input_streams()
	player_attributes = make([dynamic]PlayerAttributes, 0, 8)
	enemies = make([dynamic]Enemy, 0, 32)
	bullets = make([dynamic]Bullet, 0, 128)
	bullet_spawners = make([dynamic]BulletSpawner, 0, 16)
	world = make_world()
	enemy_texture_atlas = make_enemy_texture_atlas()
	input_streams = make_input_streams()

	tilesheet = rl.LoadTexture("assets/asset_pack/character and tileset/Dungeon_Tileset.png")
	if project, ok := ldtk.load_from_file("assets/level.ldtk", context.temp_allocator).?; ok {
		world.levels = get_all_levels(project)
		world.current_level = .Hub
	}

	world.player.translation = current_spawn_point()
	rl.SetTargetFPS(60)

	ghost_shader = rl.LoadShader(nil, "assets/shaders/ghost.glsl")

	init_waves()
}

spawn_player_and_ghosts :: proc() {
	spawn_point := get_spawn_point(world.levels[world.current_level])
	world.player.translation = spawn_point
	inputs_length := len(input_streams)
	fmt.printfln("Inputs Length: %v", inputs_length)
	if inputs_length > 1 {
		for i in 1 ..< inputs_length {
			append(&ghosts, make_ghost(spawn_point))
		}
	}
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
	draw_tiles(world.levels[world.current_level], tilesheet, .Structure)
	draw_tiles(world.levels[world.current_level], tilesheet, .Decor)
	render_players()
	draw_enemies()
	draw_bullets()
	draw_ghosts()
	display_clock()
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

	relative_mouse_rotation := get_mouse_rotation(get_relative_position(world.player.translation))

	if rl.IsKeyPressed(.R) {
		reset_loop()
	}

	input := world.current_input_tick

	target_position := world.player.translation - rl.Vector2{f32(SCREEN_WIDTH), f32(SCREEN_HEIGHT)} / 2
	update_camera_position(target_position)


	u_time := f32(rl.GetTime())

	rl.SetShaderValue(ghost_shader, rl.GetShaderLocation(ghost_shader, "u_time"), &u_time, .FLOAT)


	if world.current_level == .Level {

		player_shoot()
	}

	world.simulation_time += rl.GetFrameTime()
	for world.simulation_time >= TICK_RATE {
		read_input(relative_mouse_rotation)
		write_input_to_stream()
		physics_step()
		world.current_tick += 1
		world.simulation_time -= TICK_RATE
		if rl.IsKeyPressed(.END) {
			player_wins_wave()
		}


		if world.current_level == .Hub {

			world.current_tick = 0
		}

		if world.current_level == .Level {


			// these can be update technically only when moving, if we want to limit the calls
			// or / also at only certain intervals if we want
			cells := level.cell_grid

			grid_position := (world.player.translation - level.position) / TILE_SIZE

			cost_map = pathfinding.generate_cost_map(cells, [2]int{int(grid_position.x), int(grid_position.y)})
			flow_field = pathfinding.generate_flow_field(cost_map, cells)

			if world.current_tick >= TIME_LIMIT {
				player_wins_wave()
				return
			}

			if wave, ok := waves[world.loop_number][world.current_tick].?; ok {
				spawn_wave(wave, level)
			}

			update_enemies(flow_field)
			enemy_transition_state()
		}
	}

	handle_triggers(&world)

}

clear_dynamic_collections :: proc() {
	clear(&bullet_spawners)
	clear(&bullets)
	clear(&ghosts)
	clear(&enemies)
}

shutdown :: proc() {
	rl.UnloadRenderTexture(screen_texture)
	rl.CloseWindow()
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

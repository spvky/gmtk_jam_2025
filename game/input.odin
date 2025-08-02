package game

import "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"


InputStream :: [TIME_LIMIT]InputTick

Button :: enum u8 {
	Shoot,
	Roll,
}

InputTick :: struct {
	direction:      Vec2,
	buttons:        bit_set[Button],
	mouse_rotation: f32,
}

InputMode :: enum {
	Live,
	Playback,
}

get_mouse_rotation :: proc(relative_position: rl.Vector2) -> f32 {
	normalized_mouse_position := rl.GetMousePosition() / {f32(WINDOW_WIDTH), f32(WINDOW_HEIGHT)}

	screen_space_mouse_position := normalized_mouse_position * {SCREEN_WIDTH, SCREEN_HEIGHT}

	offset := screen_space_mouse_position - relative_position

	return math.atan2(offset.y, offset.x)

}


read_input :: proc(mouse_rotation: f32) {
	direction: Vec2
	if rl.IsKeyDown(.A) {
		direction.x -= 1
	}
	if rl.IsKeyDown(.D) {
		direction.x += 1
	}
	if rl.IsKeyDown(.S) {
		direction.y += 1
	}
	if rl.IsKeyDown(.W) {
		direction.y -= 1
	}

	direction_normal := l.normalize0(direction) * PLAYER_MOVESPEED * TICK_RATE
	level := world.levels[world.current_level]

	player_position := world.player.translation
	player_position += {12, 16}

	if direction_normal.x != 0 {
		check_player_position := player_position
		check_player_position.x += direction_normal.x
		for tile in level.tiles {
			if !(.Collision in tile.properties) {continue}

			player_collision_rect: rl.Rectangle = {
				x      = check_player_position.x,
				y      = check_player_position.y,
				width  = 8,
				height = 8,
			}

			abs_tile_position := tile.position + level.position
			if rl.CheckCollisionRecs(
				player_collision_rect,
				{abs_tile_position.x, abs_tile_position.y, TILE_SIZE, TILE_SIZE},
			) {
				correction := abs_tile_position.x - player_position.x - 8
				if direction_normal.x < 0 {
					correction = abs_tile_position.x + 16 - player_position.x
				}
				direction_normal.x = correction
				player_position.x += correction
				break
			}
		}
	}

	if direction_normal.y != 0 {
		check_player_position := player_position
		check_player_position.y += direction_normal.y
		for tile in level.tiles {
			if !(.Collision in tile.properties) {continue}

			player_collision_rect: rl.Rectangle = {
				x      = check_player_position.x,
				y      = check_player_position.y,
				width  = 8,
				height = 8,
			}

			abs_tile_position := tile.position + level.position
			if rl.CheckCollisionRecs(
				player_collision_rect,
				{abs_tile_position.x, abs_tile_position.y, TILE_SIZE, TILE_SIZE},
			) {
				correction := abs_tile_position.y - player_position.y - 8
				if direction_normal.y < 0 {
					correction = abs_tile_position.y + 16 - player_position.y
				}
				direction_normal.y = correction
				break
			}
		}
	}

	buttons: bit_set[Button]

	if rl.IsKeyDown(.SPACE) || rl.IsMouseButtonPressed(.LEFT) {
		buttons = buttons | {.Shoot}
	}
	if rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT) {
		buttons = buttons | {.Roll}
	}

	world.current_input_tick = InputTick {
		direction      = direction_normal,
		buttons        = buttons,
		mouse_rotation = mouse_rotation,
	}

}

write_input_to_stream :: proc() {
	input_streams[0][world.current_tick] = world.current_input_tick
}

make_input_streams :: proc() -> [dynamic]InputStream {
	return make([dynamic]InputStream, 2, 8)
}

destroy_input_streams :: proc() {
	delete(input_streams)
}

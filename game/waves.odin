package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

Wave_Kind :: union {
	Wave_Circle,
	Wave_Line,
	Wave_Area,
	rl.Rectangle,
}

Wave_Circle :: struct {
	radius:   f32,
	location: Vec2,
}

Wave_Line :: struct {
	start: Vec2,
	end:   Vec2,
}

Wave_Area :: struct {
	radius:   f32,
	location: Vec2,
}

Wave :: struct {
	kind:       Wave_Kind,
	amount:     u16,
	enemy_type: EnemyTag,
}

// [loop]  [game tick]
Waves :: [8][TIME_LIMIT]Maybe(Wave)
waves: Waves
init_waves :: proc() {
	//first;loop
	waves[0][60] = Wave {
		kind       = Wave_Area{100, {200, 120}},
		amount     = 16,
		enemy_type = .Skeleton,
	}

	waves[0][120] = Wave {
		kind       = Wave_Area{100, {200, 120}},
		amount     = 5,
		enemy_type = .Vampire,
	}

	waves[0][160] = Wave {
		kind = Wave_Line{start = {600, 120}, end = {700, 120}},
		amount = 8,
		enemy_type = .Vampire,
	}

	waves[0][160] = Wave {
		kind = Wave_Line{start = {300, 220}, end = {700, 220}},
		amount = 10,
		enemy_type = .Skeleton,
	}
}


level_collision :: proc(position: Vec2) -> bool {
	level := world.levels[world.current_level]
	for tile in level.tiles {
		if !(.Collision in tile.properties) {continue}

		enemy_collision_rect: rl.Rectangle = {
			x      = position.x,
			y      = position.y,
			width  = 16,
			height = 16,
		}

		abs_tile_position := tile.position + level.position
		if rl.CheckCollisionRecs(
			enemy_collision_rect,
			{abs_tile_position.x, abs_tile_position.y, TILE_SIZE, TILE_SIZE},
		) {
			return true
		}
	}

	return false
}

spawn_wave :: proc(wave: Wave, level: Level) {
	amount := wave.amount
	switch kind in wave.kind {
	case Wave_Area:
		for i in 0 ..< amount {
			angle := f32(i) / f32(amount) * (math.PI * 2)
			offset: Vec2 = {math.cos(angle), math.sin(angle)} * kind.radius
			spawn_position := kind.location + offset + level.position
			if !level_collision(spawn_position) {
				append(&enemies, make_enemy(wave.enemy_type, spawn_position))
			}
		}
	case Wave_Circle:
		for i in 0 ..< amount {
			angle := f32(i) / f32(amount) * (math.PI * 2)
			offset: Vec2 = {math.cos(angle), math.sin(angle)} * kind.radius
			spawn_position := kind.location + offset + level.position
			if !level_collision(spawn_position) {
				append(&enemies, make_enemy(wave.enemy_type, spawn_position))
			}
		}
	case Wave_Line:
		for i in 0 ..< amount {
			spawn_position := kind.start + (kind.end - kind.start) * (f32(i) / f32(amount)) + level.position
			if !level_collision(spawn_position) {
				append(&enemies, make_enemy(wave.enemy_type, spawn_position))
			}
		}
	case rl.Rectangle:
	// TODO
	}
}

package game

import ldtk "../ldtk"
import "core:fmt"
import "core:math"
import "pathfinding"
import rl "vendor:raylib"

TILE_SIZE :: 16

Level :: struct {
	tiles:     [dynamic]Tile,
	width:     int,
	height:    int,
	position:  rl.Vector2,
	entities:  [dynamic]Entity,

	// for pathfinding
	cell_grid: [][]pathfinding.Cell,
}

Level_Enum :: enum {
	Hub,
	Level,
}

Tile :: struct {
	draw_coords: rl.Rectangle,
	rotation:    f32,
	alpha:       f32,
	position:    rl.Vector2,
	properties:  bit_set[Tile_Property],
}

Tile_Property :: enum {
	Collision,
	Harmful,
}

Entity :: struct {
	type:     Entity_Type,
	position: rl.Vector2,
	tile:     Maybe(ldtk.Tileset_Rectangle),
}

Entity_Type :: enum {
	Player_Spawn,
}

get_all_levels :: proc(project: ldtk.Project) -> [dynamic]Level {

	levels: [dynamic]Level

	for ldtk_level in project.levels {
		level := load_level(ldtk_level, project.defs.tilesets[0])
		level.cell_grid = generate_cell_grid(level)
		append(&levels, level)
	}
	return levels
}

load_level :: proc(level: ldtk.Level, tileset_def: ldtk.Tileset_Definition) -> Level {
	tiles: [dynamic]Tile
	entities: [dynamic]Entity

	for layer in level.layer_instances {
		switch layer.type {

		case .Entities:
			for entity in layer.entity_instances {
				add_entity(&entities, entity)
			}
		case .Tiles:
			for tile in layer.grid_tiles {
				add_tile(&tiles, tileset_def, tile)
			}
		case .AutoLayer, .IntGrid:
			for tile in layer.auto_layer_tiles {
				add_tile(&tiles, tileset_def, tile)
			}
		}
	}

	return Level {
		entities = entities,
		tiles = tiles,
		height = level.px_height,
		width = level.px_width,
		position = {f32(level.world_x), f32(level.world_y)},
	}
}

get_tile_properties :: proc(properties: [dynamic]string) -> bit_set[Tile_Property] {
	property_set: bit_set[Tile_Property]
	for val in properties {
		switch val {

		case "Collision":
			property_set = property_set | {.Collision}

		case "Harmful":
			property_set = property_set | {.Harmful}
		}
	}
	return property_set
}

add_tile :: proc(tiles: ^[dynamic]Tile, tileset_definition: ldtk.Tileset_Definition, tile: ldtk.Tile_Instance) {
	raw_properties: [dynamic]string
	for def in tileset_definition.enum_tags {
		found := false
		for id in def.tile_ids {
			if id == tile.t {
				found = true
				break
			}
		}
		if found {
			append(&raw_properties, def.enum_value_id)
		}
	}
	properties := get_tile_properties(raw_properties)
	delete(raw_properties)
	append(
		tiles,
		Tile {
			{f32(tile.src[0]), f32(tile.src[1]), TILE_SIZE, TILE_SIZE},
			0,
			tile.a,
			{f32(tile.px[0]), f32(tile.px[1])},
			properties,
		},
	)

}

add_entity :: proc(entities: ^[dynamic]Entity, entity_instance: ldtk.Entity_Instance) {
	entity := Entity {
		position = {f32(entity_instance.px[0]), f32(entity_instance.px[1])},
		tile     = entity_instance.tile,
	}

	switch entity_instance.identifier {
	case "Player_Spawn":
		entity.type = .Player_Spawn
	}

	append(entities, entity)
}

draw_tiles :: proc(level: Level, tilesheet: rl.Texture) {
	for tile in level.tiles {
		relative_position := get_relative_position(tile.position + level.position)
		relative_position.x = f32(int(relative_position.x))
		relative_position.y = f32(int(relative_position.y))

		rl.DrawTextureRec(tilesheet, tile.draw_coords, relative_position, rl.WHITE)
	}
}

get_spawn_point :: proc(level: Level) -> rl.Vector2 {
	for entity in level.entities {
		if entity.type == .Player_Spawn {
			return entity.position + level.position
		}
	}
	assert(false)
	return {0, 0}
}

generate_cell_grid :: proc(level: Level) -> [][]pathfinding.Cell {
	cells := make([][]pathfinding.Cell, level.height / TILE_SIZE)
	for i in 0 ..< level.height / TILE_SIZE {
		cells[i] = make([]pathfinding.Cell, level.width / TILE_SIZE)
		for y in 0 ..< level.width / TILE_SIZE {
			// just defaulting to high cost, if it's 0 things will get weird
			cells[i][y].cost = 1000
			cells[i][y].walkable = false
		}
	}
	for tile in level.tiles {
		cell := &cells[int(tile.position.y / TILE_SIZE)][int(tile.position.x / TILE_SIZE)]
		// TODO add cost of tile
		cell.walkable = !(.Collision in tile.properties)
		cell.cost = 1
	}

	return cells
}

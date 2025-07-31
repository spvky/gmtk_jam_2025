package pathfinding

import "core:container/queue"
import "core:math"
import l "core:math/linalg"

Vec2 :: [2]f32
IVec :: [2]int

// could simplify
// - can make alias for [2]int
// - avoid pulling in raylib here, it's just for vector math

Cell :: struct {
	walkable: bool,
	cost:     int,
}

directions := [4]IVec{
	{0, 1},
	{1, 0},
	{0, -1},
	{-1, 0}
}


generate_cost_map :: proc(grid: [][]Cell, target: IVec) -> [][]int {
	height := len(grid)
	width := len(grid[0])

	cost_map := make([][]int, height)
	for y in 0 ..< height {
		cost_map[y] = make([]int, width)
		for x in 0 ..< width {
			cost_map[y][x] = 1000
		}
	}

	q: queue.Queue([2]int)
	queue.init(&q)
	defer queue.destroy(&q)

	cost_map[target.y][target.x] = 0
	queue.push_back(&q, target)


	for queue.len(q) > 0 {
		current := queue.pop_front(&q)
		current_cost := cost_map[current.y][current.x]

		for dir in directions {
			neighbor := IVec{current.x + dir.x, current.y + dir.y}
			if neighbor.x < 0 || neighbor.y < 0 || neighbor.x >= width || neighbor.y >= height {
				continue
			}
			if !grid[neighbor.y][neighbor.x].walkable {
				continue
			}

			new_cost := current_cost + grid[neighbor.y][neighbor.x].cost
			if new_cost < cost_map[neighbor.y][neighbor.x] {
				cost_map[neighbor.y][neighbor.x] = new_cost
				queue.push_back(&q, neighbor)
			}
		}
	}

	return cost_map
}

generate_flow_field :: proc(cost_map: [][]int, grid: [][]Cell) -> [][]Vec2 {
	height := len(cost_map)
	width := len(cost_map[0])

	flow_field := make([][]Vec2, height)
	for y in 0 ..< height {
		flow_field[y] = make([]Vec2, width)
	}


	for y in 0 ..< height {
		for x in 0 ..< width {
			best_cost := cost_map[y][x]
			best_dir := Vec2{0, 0}

			for dir in directions {
				nx := x + dir.x
				ny := y + dir.y

				if nx < 0 || ny < 0 || nx >= width || ny >= height {
					continue
				}

				neighbor_cost := cost_map[ny][nx]
				if neighbor_cost < best_cost {
					best_cost = neighbor_cost
					best_dir = l.normalize(Vec2{f32(dir.x), f32(dir.y)})
				}
			}

			flow_field[y][x] = best_dir
		}
	}

	return flow_field
}

// TODO deprecate so we can remove raylib import
debug_draw :: proc(flow_field: [][]rl.Vector2, tile_size: int) {
	for y in 0 ..< len(flow_field) {
		for x in 0 ..< len(flow_field[0]) {
			value := flow_field[y][x]
			rl.DrawText(
				rl.TextFormat("%d %d", i32(value.x), i32(value.y)),
				i32(x * tile_size),
				i32(y * tile_size),
				5,
				rl.RED,
			)
		}
	}
}

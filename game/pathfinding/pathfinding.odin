package pathfinding

import "core:container/queue"
import "core:math"
import l "core:math/linalg"

Vec2 :: [2]f32
IVec :: [2]int

Cell :: struct {
	walkable: bool,
	cost:     int,
}

directions := [8]IVec{{0, 1}, {1, 0}, {0, -1}, {-1, 0}, {-1, -1}, {-1, 1}, {1, -1}, {1, 1}}
// directions := [4]IVec{{0, 1}, {1, 0}, {0, -1}, {-1, 0}}


generate_cost_map :: proc(grid: [][]Cell, target: IVec) -> [][]int {
	height := len(grid)
	width := len(grid[0])

	cost_map := make([][]int, height, allocator = context.temp_allocator)
	for y in 0 ..< height {
		cost_map[y] = make([]int, width, allocator = context.temp_allocator)
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

	// we might not want the lifetime of this to only be one frame
	// but we can keep it like this for now and be more conservative with pathfinding updates
	// if we notice it's performance being influenced
	flow_field := make([][]Vec2, height, allocator = context.temp_allocator)
	for y in 0 ..< height {
		flow_field[y] = make([]Vec2, width, allocator = context.temp_allocator)
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

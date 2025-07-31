package game

import rl "vendor:raylib"

Enemy :: struct {
	position: rl.Vector2,
}

update_enemy :: proc(flow_field: [][]rl.Vector2, enemy: ^Enemy) {

	grid_position := (enemy.position / TILE_SIZE)
	direction := flow_field[int(grid_position.y)][int(grid_position.x)]
	enemy.position += direction

}

draw_enemy :: proc(enemy: Enemy) {
	rl.DrawCircleV(get_relative_position(enemy.position), 8, rl.RED)
}

package game

import rl "vendor:raylib"

Player :: struct {
	tag:         PlayerTag,
	translation: Vec2,
	velocity:    Vec2,
	radius:      f32,
}

PlayerTag :: enum {
	Player,
	Ghost,
}

make_player :: proc(tag: PlayerTag) -> Player {
	return Player{tag = tag, radius = 20}
}

render_players :: proc() {
	player := world.player
	color := player.tag == .Player ? rl.BLUE : rl.WHITE

	relative_position := get_relative_position(player.translation)
	rl.DrawCircleV(relative_position, 20, color)
}

set_player_velocities :: proc() {
	player := &world.player
	input := world.current_input_tick
	new_velo := direction_to_vec(input.direction)

	player.velocity = new_velo * 50
}

apply_player_velocities :: proc() {
	world.player.translation += world.player.velocity * TICK_RATE
}

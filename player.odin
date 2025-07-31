package main

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
	for player in world.players {
		color := player.tag == .Player ? rl.BLUE : rl.WHITE
		rl.DrawCircleV(player.translation, player.radius, color)
	}
}

set_player_velocities :: proc() {
	for &player, i in world.players {
		input := input_streams[i][world.current_tick]
		new_velo := direction_to_vec(input.direction)
		player.velocity = new_velo * 50
	}
}

apply_player_velocities :: proc() {
	for &player in world.players {
		player.translation += player.velocity * TICK_RATE
	}
}

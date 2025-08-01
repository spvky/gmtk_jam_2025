package game

import "core:fmt"
import l "core:math/linalg"
import rl "vendor:raylib"

PLAYER_MOVESPEED :: 100
PLAYER_ROLL_DISTANCE :: 100

Player :: struct {
	state:          PlayerState,
	translation:    Vec2,
	velocity:       Vec2,
	radius:         f32,
	dodge_cooldown: f32,
}

PlayerState :: union {
	PlayerMoving,
	PlayerDodging,
}

PlayerMoving :: struct {}
PlayerDodging :: struct {
	target:   Vec2,
	duration: f32,
	progress: f32,
}

make_player :: proc() -> Player {
	return Player{radius = 8, state = PlayerMoving{}}
}

render_players :: proc() {
	player := world.player
	color := rl.BLUE

	relative_position := get_relative_position(player.translation)
	rl.DrawRectangleV(relative_position, {player.radius * 2, player.radius * 2}, color)
}

player_dodge :: proc() {
	player := &world.player
	input := world.current_input_tick
	should_dodge := .Roll in input.buttons
	direction := direction_to_vec(input.direction)

	if player.dodge_cooldown > 0 {
		player.dodge_cooldown = clamp(player.dodge_cooldown - TICK_RATE, 0, player.dodge_cooldown)
	}

	if player.dodge_cooldown == 0 && should_dodge && input.direction != .Neutral {
		player.state = PlayerDodging {
			target   = player.translation + (direction * PLAYER_ROLL_DISTANCE),
			duration = 0.2,
		}
		player.dodge_cooldown = 1
	}
}

set_player_velocities :: proc() {
	player := &world.player
	input := world.current_input_tick
	new_velo := direction_to_vec(input.direction)
	player.velocity = new_velo * PLAYER_MOVESPEED
}

apply_player_velocities :: proc() {
	player := &world.player
	switch &state in player.state {
	case PlayerMoving:
		player.translation += player.velocity * TICK_RATE
	case PlayerDodging:
		state.progress += TICK_RATE
		amount := clamp(state.progress / state.duration, 0, 1.0)
		player.translation = l.lerp(player.translation, state.target, amount)
		if state.progress > state.duration {
			player.state = PlayerMoving{}
		}
	}
}

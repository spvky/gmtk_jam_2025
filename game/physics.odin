package game

physics_step :: proc() {
	set_player_velocities()
	player_animations()
	apply_player_velocities()
	update_ghosts()
	update_bullets()
}

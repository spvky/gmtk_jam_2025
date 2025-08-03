package game

physics_step :: proc() {
	set_player_velocities()
	apply_player_velocities()
	update_ghosts()
	update_bullets()
}

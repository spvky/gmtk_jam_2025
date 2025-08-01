package game

physics_step :: proc() {
	set_player_velocities()
	player_dodge()
	apply_player_velocities()
	update_bullets()
}

package game

import rl "vendor:raylib"

Camera :: struct {
	offset_position: rl.Vector2,
}

camera: Camera


get_relative_position :: proc(abs_position: rl.Vector2) -> rl.Vector2 {
	return abs_position - camera.offset_position
}

update_camera_position :: proc(target_position: rl.Vector2) {
	camera.offset_position += (target_position - camera.offset_position) / 20
}

package game

import rl "vendor:raylib"

Camera :: struct {
	offset_position:         rl.Vector2,
	mouse_offset_normalized: rl.Vector2,
	mouse_offset_strength:   f32,
}

camera: Camera
camera_strength_factor :: 85


get_relative_position :: proc(abs_position: Vec2) -> Vec2 {
	// how strongly the camera should follow the mouse cursor

	mouse_offset := camera.mouse_offset_normalized * camera.mouse_offset_strength * camera_strength_factor
	return abs_position - (camera.offset_position + mouse_offset)
}

update_camera_position :: proc(target_position: rl.Vector2) {
	mouse_position := rl.GetMousePosition()
	mouse_position /= {f32(WINDOW_WIDTH), f32(WINDOW_HEIGHT)}

	mouse_position -= {0.5, 0.5}

	length := rl.Vector2Length(mouse_position)

	camera.offset_position += (target_position - camera.offset_position) / 20
	camera.mouse_offset_strength = length
	camera.mouse_offset_normalized = mouse_position
}

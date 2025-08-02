package game

import "core:math"
import l "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

Ghost_Particle :: struct {
	translation: Vec2,
	velocity:    Vec2,
	lifetime:    u16,
	size:        f32,
}

Ghost :: struct {
	translation: Vec2,
	velocity:    Vec2,
	particles:   [dynamic]Ghost_Particle,
}

delay :: 120

make_ghost :: proc(translation: Vec2) -> Ghost {
	return Ghost{translation = translation}
}

ghost_shoot :: proc(ghost: ^Ghost, input: InputTick, player: PlayerAttributes) {
	translation := ghost.translation + Vec2{f32(TILE_SIZE) / 2, f32(TILE_SIZE) / 2}
	spawner: BulletSpawner
	switch player.shot_type {
	case .Normal:
		spawner = make_arc_spawner(
			tag = .Ghost,
			source = translation,
			shot_count = player.shot_amount,
			wave_count = player.shot_iterations,
			distance = 8,
			shot_cooldown = 0.05,
			angle = input.mouse_rotation,
			arc = player.shot_spread,
			speed = player.shot_speed,
		)
	case .Spiral:
		spawner = make_circle_spawner(
			tag = .Ghost,
			source = translation,
			shot_count = player.shot_amount,
			wave_count = player.shot_iterations,
			distance = 8,
			shot_cooldown = 0.05,
			rotation_speed = 360,
			travel_speed = 75,
		)
	case .Orbital:
		spawner = make_orbital_spawner(
			tag = .Ghost,
			source = translation,
			shot_count = player.shot_amount,
			wave_count = player.shot_iterations,
			distance = 8,
			shot_cooldown = 0.05,
			angle = input.mouse_rotation,
			speed = player.shot_speed,
			radius = 10,
			rotation_speed = 720,
		)
	}
	append(&bullet_spawners, spawner)
}

apply_ghost_inputs :: proc(ghost: ^Ghost, input: InputTick, player: PlayerAttributes) {
	ghost.velocity = input.direction
	// TODO treat 'dodge roll'
	ghost.translation += ghost.velocity

	if .Shoot in input.buttons {
		ghost_shoot(ghost, input, player)
	}
}

update_ghosts :: proc() {
	if delay >= world.current_tick {
		return
	}


	for i in 0 ..< len(ghosts) {
		ghost := &ghosts[i]
		apply_ghost_inputs(ghost, input_streams[i + 1][world.current_tick - delay], player_attributes[i])


		i := len(ghost.particles) - 1
		for i > 0 {
			particle := &ghost.particles[i]
			particle.lifetime -= 1

			particle.translation += particle.velocity

			if particle.lifetime == 0 {
				ordered_remove(&ghost.particles, i)
			}
			i -= 1
		}

		if world.current_tick % 4 == 0 {
			inital_particle_velocity: rl.Vector2 = {math.sin(f32(world.current_tick) * 0.5) * 0.2, 0.2}

			initial_particle_position := ghost.translation

			// offset to center of ghost
			initial_particle_position += {8, 8}
			// offset by a varying amount in the x axis
			initial_particle_position += {2 * math.cos(f32(world.current_tick)), 0}

			particle_size := (rand.float32() * 3) + 3
			append(
				&ghost.particles,
				Ghost_Particle {
					velocity = inital_particle_velocity,
					translation = initial_particle_position,
					lifetime = 45,
					size = particle_size,
				},
			)
		}

		if world.current_tick % 8 == 0 {
			inital_particle_velocity: rl.Vector2 = {math.sin(f32(world.current_tick) * 0.25) * 0.4, -0.1}

			initial_particle_position := ghost.translation

			// offset to center of ghost
			initial_particle_position += {8, 8}
			// offset by a varying amount in the x axis
			initial_particle_position += {2 * math.cos(f32(world.current_tick)), 2}

			append(
				&ghost.particles,
				Ghost_Particle {
					velocity = inital_particle_velocity,
					translation = initial_particle_position,
					lifetime = 55,
					size = 8,
				},
			)
		}
	}
}

draw_ghosts :: proc() {
	if delay >= world.current_tick {
		return
	}

	for i in 0 ..< len(ghosts) {
		ghost := ghosts[i]
		rl.BeginShaderMode(ghost_shader)
		for particle in ghost.particles {
			rl.DrawCircleV(get_relative_position(particle.translation), particle.size / 2, rl.WHITE)
		}
		// TODO actually animate ghost, instead of stealing from player

		player := world.player
		current_frame := player.animation_player.current_frame
		x_position := f32(current_frame % 6) * 32
		y_position := f32(current_frame / 6) * 32
		source_rect := rl.Rectangle {
			x      = x_position,
			y      = y_position,
			width  = 32,
			height = 32,
		}

		rl.DrawTextureRec(
			player.animation_player.texture^,
			source_rect,
			get_relative_position(ghost.translation),
			rl.WHITE,
		)
		rl.EndShaderMode()
	}
}

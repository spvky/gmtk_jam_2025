package game

import "core:math"

import l "core:math/linalg"
import rl "vendor:raylib"

Ghost_Particle :: struct {
	translation: Vec2,
	velocity:    Vec2,
	lifetime:    u16,
	size:        u16,
}

Ghost :: struct {
	translation: Vec2,
	velocity:    Vec2,
	particles:   [dynamic]Ghost_Particle,
}

delay :: 120

apply_ghost_inputs :: proc(ghost: ^Ghost, input: InputTick) {
	new_velo := direction_to_vec(input.direction)
	ghost.velocity = new_velo * PLAYER_MOVESPEED

	// TODO treat things like 'shoot' and 'dodge roll'
	ghost.translation += ghost.velocity * TICK_RATE
}

update_ghosts :: proc() {
	if delay >= world.current_tick {
		return
	}


	for i in 0 ..< len(ghosts) {
		ghost := &ghosts[i]
		apply_ghost_inputs(ghost, input_streams[i][world.current_tick - delay])
		//apply_ghost_inputs(ghost, input_streams[i + 1][world.current_tick - delay])


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

			append(
				&ghost.particles,
				Ghost_Particle {
					velocity = inital_particle_velocity,
					translation = initial_particle_position,
					lifetime = 45,
					size = 6,
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
			rl.DrawRectangleV(
				get_relative_position(particle.translation),
				{f32(particle.size), f32(particle.size)},
				rl.WHITE,
			)
		}

		// TODO draw any real animated texture here, instead of rectangle
		rl.DrawRectangleV(get_relative_position(ghost.translation), {16, 16}, rl.WHITE)
		rl.EndShaderMode()
	}
}

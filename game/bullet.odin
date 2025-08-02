package game

import "core:fmt"
import m "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"

BULLET_RADIUS :: 3

BulletControl :: struct {
	bullet_progress:    f32,
	bullet_color_index: int,
	bullet_color:       [BulletTag][3]rl.Color,
}

BulletTag :: enum {
	Player,
	Enemy,
	Ghost,
}

ShotType :: enum {
	Normal,
	Spiral,
	Orbital,
}

Bullet :: struct {
	tag:          BulletTag,
	path:         BulletPath,
	position:     Vec2,
	current_life: f32,
	lifetime:     f32,
}

BulletSpawner :: struct {
	tag:           BulletTag,
	position:      Vec2,
	wave_count:    int,
	waves_fired:   int,
	shot_count:    int,
	distance:      f32,
	bullet_path:   BulletPath,
	shot_cooldown: f32,
	shot_progress: f32,
}

BulletPath :: union #no_nil {
	StraightPath,
	SpiralPath,
	OrbitalPath,
}

StraightPath :: struct {
	angle: f32,
	speed: f32,
	arc:   f32,
}

SpiralPath :: struct {
	anchor:         Vec2,
	current_angle:  f32,
	current_radius: f32,
	travel_speed:   f32,
	rotation_speed: f32,
}

OrbitalPath :: struct {
	anchor:         Vec2,
	angle:          f32,
	speed:          f32,
	current_angle:  f32,
	radius:         f32,
	rotation_speed: f32,
}

make_arc_shot :: proc(tag: BulletTag, source: Vec2, angle: f32, amount: int, arc: f32, speed: f32 = 160) {
	if amount > 1 {
		min_angle := l.to_degrees(angle) - arc / 2
		arc_increment := arc / f32(amount)

		for i in 0 ..= amount {
			shot_angle := min_angle + (f32(i) * arc_increment)
			append(
				&bullets,
				Bullet {
					tag = tag,
					position = source,
					path = StraightPath{angle = l.to_radians(shot_angle), speed = speed},
					lifetime = 20,
				},
			)
		}
	} else {
		append(
			&bullets,
			Bullet{tag = tag, position = source, path = StraightPath{angle = angle, speed = speed}, lifetime = 20},
		)
	}
}

make_spiral_shot :: proc(
	tag: BulletTag,
	source: Vec2,
	shot_count: int,
	distance: f32,
	rotation_speed, travel_speed: f32,
) {
	angle_between := 360.0 / f32(shot_count)
	for i in 0 ..< shot_count {
		angle := f32(i) * angle_between
		append(
			&bullets,
			Bullet {
				tag = tag,
				position = source,
				path = SpiralPath {
					anchor = source,
					current_angle = l.to_radians(angle),
					travel_speed = travel_speed,
					rotation_speed = rotation_speed,
				},
				lifetime = 10,
			},
		)
	}
}

make_orbital_shot :: proc(tag: BulletTag, source: Vec2, amount: int, angle, radius, speed, rotation_speed: f32) {
	angle_between := 360.0 / f32(amount)
	for i in 0 ..= amount {
		starting_angle := f32(i) * angle_between
		append(
			&bullets,
			Bullet {
				tag = tag,
				position = source,
				path = OrbitalPath {
					anchor = source,
					angle = angle,
					speed = speed,
					current_angle = l.to_radians(starting_angle),
					radius = radius,
					rotation_speed = rotation_speed,
				},
				lifetime = 10,
			},
		)
	}
}

make_arc_spawner :: proc(
	tag: BulletTag,
	source: Vec2,
	shot_count, wave_count: int,
	distance, shot_cooldown, angle, arc, speed: f32,
) -> BulletSpawner {
	return BulletSpawner {
		tag = tag,
		position = source,
		shot_count = shot_count,
		wave_count = wave_count,
		distance = distance,
		bullet_path = StraightPath{angle = angle, speed = speed, arc = arc},
		shot_progress = shot_cooldown,
		shot_cooldown = shot_cooldown,
	}
}

make_circle_spawner :: proc(
	tag: BulletTag,
	source: Vec2,
	shot_count, wave_count: int,
	distance, shot_cooldown, rotation_speed, travel_speed: f32,
) -> BulletSpawner {
	return BulletSpawner {
		tag = tag,
		position = source,
		shot_count = shot_count,
		wave_count = wave_count,
		distance = distance,
		bullet_path = SpiralPath{rotation_speed = rotation_speed, travel_speed = travel_speed},
		shot_progress = shot_cooldown,
		shot_cooldown = shot_cooldown,
	}
}

make_orbital_spawner :: proc(
	tag: BulletTag,
	source: Vec2,
	shot_count, wave_count: int,
	distance, shot_cooldown, angle, speed, radius, rotation_speed: f32,
) -> BulletSpawner {
	return BulletSpawner {
		tag = tag,
		position = source,
		shot_count = shot_count,
		wave_count = wave_count,
		distance = distance,
		bullet_path = OrbitalPath {
			anchor = source,
			angle = angle,
			speed = speed,
			radius = radius,
			rotation_speed = rotation_speed,
		},
		shot_progress = shot_cooldown,
		shot_cooldown = shot_cooldown,
	}
}

spawner_shoot :: proc(spawner: ^BulletSpawner) {
	switch path in spawner.bullet_path {
	case SpiralPath:
		make_spiral_shot(
			spawner.tag,
			spawner.position,
			spawner.shot_count,
			spawner.distance,
			path.rotation_speed,
			path.travel_speed,
		)
	case StraightPath:
		make_arc_shot(spawner.tag, spawner.position, path.angle, spawner.shot_count, path.arc, path.speed)
	case OrbitalPath:
		make_orbital_shot(
			spawner.tag,
			spawner.position,
			spawner.shot_count,
			path.angle,
			path.radius,
			path.speed,
			path.rotation_speed,
		)
	}

	spawner.waves_fired += 1
	spawner.shot_progress = 0
}

manage_bullet_spawners :: proc() {
	for &spawner, i in bullet_spawners {
		spawner.shot_progress += TICK_RATE
		if spawner.shot_progress > spawner.shot_cooldown {
			spawner_shoot(&spawner)
			if spawner.waves_fired == spawner.wave_count {
				unordered_remove(&bullet_spawners, i)
			}
		}
	}
}

update_bullets :: proc() {
	manage_bullet_spawners()
	manage_bullet_color()
	manage_bullet_path()
	check_bullet_collision()
}

check_bullet_collision :: proc() {
	to_remove: [dynamic]int


	for &bullet, i in bullets {

		has_collided := false

		switch bullet.tag {
		case .Player:
			for &enemy in enemies {
				if rl.CheckCollisionCircles(bullet.position, BULLET_RADIUS, enemy.position, 8) && !has_collided {
					has_collided = true
					if enemy.health > 0 {
						enemy.health -= 1

					}
					enemy.damaged_timer = ENEMY_DAMAGE_TIME
					append(&to_remove, i)


				}
			}

		case .Enemy:
			if rl.CheckCollisionCircles(bullet.position, BULLET_RADIUS, world.player.translation, 8) && !has_collided {
				has_collided = true
				if world.player.health > 0 {
					world.player.health -= 1
				}
				append(&to_remove, i)
			}

		case .Ghost:
			if rl.CheckCollisionCircles(bullet.position, BULLET_RADIUS, world.player.translation, 8) && !has_collided {
				has_collided = true
				kill_player()
				append(&to_remove, i)
			}
		}

		level := world.levels[world.current_level]
		for tile in level.tiles {
			if .Collision in tile.properties {

				tile_rec := rl.Rectangle{tile.position[0], tile.position[1], TILE_SIZE, TILE_SIZE}
				if rl.CheckCollisionCircleRec(bullet.position, BULLET_RADIUS, tile_rec) {
					has_collided = true
					append(&to_remove, i)
				}

			}
		}

	}

	for i in to_remove {
		unordered_remove(&bullets, i)
		clear(&to_remove)
	}
}


draw_bullets :: proc() {
	for bullet in bullets {
		pos := get_relative_position(bullet.position)
		rl.DrawCircleV(pos, BULLET_RADIUS, bullet_control.bullet_color[bullet.tag][bullet_control.bullet_color_index])
	}
}

manage_bullet_color :: proc() {
	bullet_control.bullet_progress += TICK_RATE
	if bullet_control.bullet_progress > 0.1 {
		bullet_control.bullet_progress = 0
		bullet_control.bullet_color_index += 1
		if bullet_control.bullet_color_index > 2 {
			bullet_control.bullet_color_index = 0
		}
	}
}

manage_bullet_path :: proc() {
	for &bullet, i in bullets {
		switch &path in bullet.path {
		case StraightPath:
			direction := l.normalize(Vec2{m.cos(path.angle), m.sin(path.angle)})
			bullet.position += direction * path.speed * TICK_RATE
		case SpiralPath:
			bullet.position.x = path.anchor.x + path.current_radius * m.cos(path.current_angle)
			bullet.position.y = path.anchor.y + path.current_radius * m.sin(path.current_angle)
			path.current_radius += path.travel_speed * TICK_RATE
			path.current_angle += l.to_radians(path.rotation_speed) * TICK_RATE
		case OrbitalPath:
			direction := l.normalize(Vec2{m.cos(path.angle), m.sin(path.angle)})
			path.anchor += direction * path.speed * TICK_RATE
			bullet.position.x = path.anchor.x + path.radius * m.cos(path.current_angle)
			bullet.position.y = path.anchor.y + path.radius * m.sin(path.current_angle)
			path.current_angle += l.to_radians(path.rotation_speed) * TICK_RATE
		}
		bullet.current_life += TICK_RATE
		if bullet.current_life > bullet.lifetime {
			unordered_remove(&bullets, i)
		}
	}
}

package game

import m "core:math"
import l "core:math/linalg"
import rl "vendor:raylib"

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

Bullet :: struct {
	tag:          BulletTag,
	path:         BulletPath,
	position:     Vec2,
	current_life: f32,
	lifetime:     f32,
}

BulletSpawner :: struct {
	tag:            BulletTag,
	position:       Vec2,
	wave_count:     int,
	waves_fired:    int,
	shot_count:     int,
	distance:       f32,
	rotation_speed: f32,
	travel_speed:   f32,
	shot_cooldown:  f32,
	shot_progress:  f32,
}

BulletPath :: union #no_nil {
	StraightPath,
	SpiralPath,
}

StraightPath :: struct {
	angle: f32,
	speed: f32,
}

SpiralPath :: struct {
	anchor:         Vec2,
	current_angle:  f32,
	current_radius: f32,
	expand_speed:   f32,
	rotation_speed: f32,
}

make_spiral_bullet :: proc(
	tag: BulletTag,
	anchor: Vec2,
	starting_angle: f32,
	starting_radius: f32,
	expand_speed: f32,
	rotation_speed: f32,
) -> Bullet {
	return Bullet {
		tag = tag,
		position = anchor,
		path = SpiralPath {
			anchor = anchor,
			current_angle = l.to_radians(starting_angle),
			current_radius = starting_radius,
			expand_speed = expand_speed,
			rotation_speed = rotation_speed,
		},
		lifetime = 2,
	}
}

make_bullet_arc :: proc(tag: BulletTag, source: Vec2, angle: f32, amount: int, arc: f32) {
	if amount > 1 {
		min_angle := l.to_degrees(angle) - arc / 2
		arc_increment := arc / f32(amount)

		for i in 0 ..= amount {
			shot_angle := min_angle + (f32(i) * arc_increment)
			append(
				&bullets,
				Bullet {
					tag = tag,
					path = StraightPath{l.to_radians(shot_angle), 160},
					position = source,
					lifetime = 20,
				},
			)
		}
	} else {
		append(&bullets, Bullet{tag = tag, path = StraightPath{angle, 160}, position = source, lifetime = 20})
	}
}

make_shot_circle :: proc(
	tag: BulletTag,
	source: Vec2,
	shot_count: int,
	distance: f32,
	rotation_speed, spread_speed: f32,
) {
	angle_between := 360.0 / f32(shot_count)
	for i in 0 ..= shot_count {
		angle := f32(i) * angle_between
		append(&bullets, make_spiral_bullet(tag, source, angle, distance, spread_speed, rotation_speed))
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
		rotation_speed = rotation_speed,
		travel_speed = travel_speed,
		shot_progress = shot_cooldown,
		shot_cooldown = shot_cooldown,
	}
}

spawner_shoot :: proc(spawner: ^BulletSpawner) {
	make_shot_circle(
		spawner.tag,
		spawner.position,
		spawner.shot_count,
		spawner.distance,
		spawner.rotation_speed,
		spawner.travel_speed,
	)
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
}

draw_bullets :: proc() {
	for bullet in bullets {
		pos := get_relative_position(bullet.position)
		rl.DrawCircleV(pos, 3, bullet_control.bullet_color[bullet.tag][bullet_control.bullet_color_index])
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
			path.current_radius += path.expand_speed * TICK_RATE
			path.current_angle += l.to_radians(path.rotation_speed) * TICK_RATE
		}
		bullet.current_life += TICK_RATE
		if bullet.current_life > bullet.lifetime {
			unordered_remove(&bullets, i)
		}
	}
}

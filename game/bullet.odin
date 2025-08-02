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
	WavePath,
}

StraightPath :: struct {
	angle: f32,
	speed: f32,
	arc:   f32,
}

WavePath :: struct {
	angle:      f32,
	speed:      f32,
	arc:        f32,
	wave_speed: f32,
	wave_depth: f32,
}

SpiralPath :: struct {
	anchor:         Vec2,
	current_angle:  f32,
	current_radius: f32,
	travel_speed:   f32,
	rotation_speed: f32,
}

make_spiral_bullet :: proc(
	tag: BulletTag,
	anchor: Vec2,
	starting_angle: f32,
	starting_radius: f32,
	travel_speed: f32,
	rotation_speed: f32,
) -> Bullet {
	return Bullet {
		tag = tag,
		position = anchor,
		path = SpiralPath {
			anchor = anchor,
			current_angle = l.to_radians(starting_angle),
			current_radius = starting_radius,
			travel_speed = travel_speed,
			rotation_speed = rotation_speed,
		},
		lifetime = 2,
	}
}
make_straight_bullet :: proc(tag: BulletTag, source: Vec2, angle: f32, speed: f32) -> Bullet {
	return Bullet{tag = tag, position = source, path = StraightPath{angle = angle, speed = speed}, lifetime = 20}
}

make_wave_bullet :: proc(tag: BulletTag, source: Vec2, angle, speed, wave_speed, wave_depth: f32) -> Bullet {
	return Bullet {
		tag = tag,
		position = source,
		path = WavePath{angle = angle, speed = speed, wave_speed = wave_speed, wave_depth = wave_depth},
		lifetime = 20,
	}
}

make_arc_shot :: proc(tag: BulletTag, source: Vec2, angle: f32, amount: int, arc: f32, speed: f32 = 160) {
	if amount > 1 {
		min_angle := l.to_degrees(angle) - arc / 2
		arc_increment := arc / f32(amount)

		for i in 0 ..= amount {
			shot_angle := min_angle + (f32(i) * arc_increment)
			append(&bullets, make_straight_bullet(tag, source, l.to_radians(shot_angle), speed))
		}
	} else {
		append(&bullets, make_straight_bullet(tag, source, angle, speed))
	}
}

make_spiral_shot :: proc(
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

make_wave_shot :: proc(tag: BulletTag, source: Vec2, angle: f32, amount: int, arc: f32, speed: f32 = 160) {
	if amount > 1 {
		min_angle := l.to_degrees(angle) - arc / 2
		arc_increment := arc / f32(amount)

		for i in 0 ..= amount {
			shot_angle := min_angle + (f32(i) * arc_increment)
			append(&bullets, make_wave_bullet(tag, source, l.to_radians(shot_angle), speed, 10, 20))
		}
	} else {
		append(&bullets, make_wave_bullet(tag, source, angle, speed, 10, 20))
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

import "core:fmt"

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
	case WavePath:
		make_wave_shot(spawner.tag, spawner.position, path.angle, spawner.shot_count, path.arc, path.speed)
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
			path.current_radius += path.travel_speed * TICK_RATE
			path.current_angle += l.to_radians(path.rotation_speed) * TICK_RATE
		case WavePath:
			direction := l.normalize(
				Vec2 {
					m.cos(path.angle) * (m.sin(bullet.current_life * path.wave_speed) * path.wave_depth),
					m.sin(path.angle) * (m.cos(bullet.current_life * path.wave_speed) * path.wave_depth),
				},
			)
			bullet.position += direction * path.speed * TICK_RATE
		}
		bullet.current_life += TICK_RATE
		if bullet.current_life > bullet.lifetime {
			unordered_remove(&bullets, i)
		}
	}
}

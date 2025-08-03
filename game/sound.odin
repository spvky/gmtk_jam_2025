package game

import rl "vendor:raylib"

Sound :: enum {
	PlayerShoot,
	PlayerHit,
	EnemyHit,
}

load_sounds :: proc() -> [Sound]rl.Sound {
	rl.SetMasterVolume(0.2)
	return [Sound]rl.Sound {
		.PlayerShoot = rl.LoadSound("assets/sounds/player_shoot.wav"),
		.PlayerHit = rl.LoadSound("assets/sounds/player_hit.wav"),
		.EnemyHit = rl.LoadSound("assets/sounds/enemy_hit.wav"),
	}
}

play_sound :: proc(sound_tag: Sound) {
	rl.PlaySound(sounds[sound_tag])
}

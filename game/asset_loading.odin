package game

import rl "vendor:raylib"

enemy_texture_atlas: [EnemyTag]rl.Texture

make_enemy_texture_atlas :: proc() -> [EnemyTag]rl.Texture {
	skeleton := rl.LoadTexture("assets/sprites/skeleton1.png")
	vampire := rl.LoadTexture("assets/sprites/vampire.png")
	return [EnemyTag]rl.Texture{.Skeleton = skeleton, .Vampire = vampire}
}

package game

import rl "vendor:raylib"

enemy_texture_atlas: [EnemyTag]rl.Texture
character_texture_atlas: [Character_Tag]rl.Texture

make_enemy_texture_atlas :: proc() -> [EnemyTag]rl.Texture {
	skeleton := rl.LoadTexture("assets/sprites/skeleton1.png")
	vampire := rl.LoadTexture("assets/sprites/vampire.png")
	return [EnemyTag]rl.Texture{.Skeleton = skeleton, .Vampire = vampire}
}

make_character_texture_atlas :: proc() -> [Character_Tag]rl.Texture {
	mini_noble_woman := rl.LoadTexture("assets/characters/MiniNobleWoman.png")
	return [Character_Tag]rl.Texture{.MiniNobleWoman = mini_noble_woman}
}

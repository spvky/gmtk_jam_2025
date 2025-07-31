package game

import rl "vendor:raylib"

texture_atlas: [TextureType]rl.Texture

TextureType :: enum {
	Skeleton,
}

make_texture_atlas :: proc() -> [TextureType]rl.Texture {
	skeleton := rl.LoadTexture("assets/sprites/skeleton1.png")
	return [TextureType]rl.Texture{.Skeleton = skeleton}
}

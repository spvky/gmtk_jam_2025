package game

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

upgrade_sheet: rl.Texture
upgrades: [dynamic]Upgrade
UPGRADE_SIZE :: 32

Upgrade :: struct {
	type:        Upgrade_Type,
	price:       int,
	draw_coords: rl.Rectangle,
}

Upgrade_Type :: enum {
	Spread,
}

init_upgrades :: proc() {

	upgrade_sheet = rl.LoadTexture("assets/sprites/spreadshot.png")

	append(&upgrades, Upgrade{.Spread, 3, {0, 0, UPGRADE_SIZE, UPGRADE_SIZE}})

}

make_upgrades :: proc() {

	if world.current_level == .Hub {
		to_spawn: [dynamic]Upgrade

		for i in 0 ..< world.loop_number {
			append(&to_spawn, rand.choice(upgrades[:]))
		}

		for entity in world.levels[world.current_level].entities {
			for upgrade in to_spawn {
				if entity.type == .Upgrade_Spawn {
					draw_upgrade(upgrade, entity.position)
					fmt.printfln("spawned upgrade: %v", upgrade.type)
				}
			}

		}

		clear(&to_spawn)
	}
}

draw_upgrade :: proc(upgrade: Upgrade, pos: Vec2) {

	relative_pos := get_relative_position(pos)
	rl.DrawTextureRec(upgrade_sheet, upgrade.draw_coords, relative_pos, rl.WHITE)

}

package game

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

upgrade_sheet: rl.Texture
upgrade_choices: [dynamic]Upgrade
upgrades: [dynamic]Upgrade
UPGRADE_SIZE :: 32

Upgrade :: struct {
	type:        Upgrade_Type,
	price:       int,
	draw_coords: rl.Rectangle,
	pos:         Vec2,
	state:       Upgrade_State,
}

Upgrade_State :: enum {
	Idle,
	Hover,
}

Upgrade_Type :: enum {
	Spread,
}

init_upgrades :: proc() {

	upgrade_sheet = rl.LoadTexture("assets/sprites/spreadshot.png")

	append(&upgrade_choices, Upgrade{.Spread, 3, {0, 0, UPGRADE_SIZE, UPGRADE_SIZE}, {0, 0}, .Idle})

}

clear_upgrades :: proc() {
	clear(&upgrades)
}

pick_upgrades :: proc() -> [dynamic]Upgrade {

	to_spawn: [dynamic]Upgrade

	count := math.clamp((world.loop_number + 1) / 2, 1, 4)

	for i in 0 ..< count {
		append(&to_spawn, rand.choice(upgrade_choices[:]))
	}

	return to_spawn

}

make_upgrades :: proc() {

	prev_entity: Entity
	to_spawn := pick_upgrades()
	fmt.println(len(to_spawn))
	upgrades_spawned: int

	for entity in world.levels[world.current_level].entities {
		for &upgrade in to_spawn {
			if entity.type == .Upgrade_Spawn &&
			   upgrades_spawned < len(to_spawn) &&
			   entity.position != prev_entity.position {


				upgrade.pos = entity.position
				append(&upgrades, upgrade)
				upgrades_spawned += 1
				prev_entity = entity
				fmt.println("made upgrade")


			}
		}

	}
	upgrades_spawned = 0

	clear(&to_spawn)

}

draw_upgrades :: proc() {

	for upgrade in upgrades {

		rl.DrawTextureRec(upgrade_sheet, upgrade.draw_coords, get_relative_position(upgrade.pos), rl.WHITE)

	}

}

apply_upgrade :: proc(type: Upgrade_Type) {
	attributes := &player_attributes[0]
	switch type {
	case .Spread:
		attributes.shot_amount = 4
		attributes.shot_spread = 30.
	}
}

update_upgrades :: proc() {

	input := world.current_input_tick
	for &upgrade in upgrades {

		idle_texture := upgrade_choices[upgrade.type].draw_coords
		hover_texture := idle_texture
		hover_texture.x += UPGRADE_SIZE

		if rl.CheckCollisionCircles(
			get_relative_position(upgrade.pos),
			16,
			get_relative_position(world.player.translation),
			8,
		) {
			upgrade.state = .Hover
		} else {upgrade.state = .Idle}

		switch upgrade.state {
		case .Idle:
			upgrade.draw_coords = idle_texture
		case .Hover:
			upgrade.draw_coords = hover_texture
			if .Interact in input.buttons {
				apply_upgrade(upgrade.type)
			}
		}
	}
}

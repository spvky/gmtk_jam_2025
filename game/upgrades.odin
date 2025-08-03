package game

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

upgrade_sheet: rl.Texture
upgrade_choices: [dynamic]Upgrade
upgrades: [dynamic]Upgrade
UPGRADE_SIZE :: 32
SPRITES_PER_ROW :: 2
SHEET_WIDTH :: 64
SHEET_HEIGHT :: 96

Upgrade :: struct {
	type:        Upgrade_Type,
	price:       int,
	draw_coords: rl.Rectangle,
	pos:         Vec2,
	state:       Upgrade_State,
	has_spawned: bool,
}

Upgrade_State :: enum {
	Idle,
	Hover,
}

Upgrade_Type :: enum {
	Spread,
	Orbital,
	Spiral,
}

Upgrade_Info :: [3]cstring {
	"Shoot an arc of projectiles forwards",
	"Shoot a spinning ring of projectiles",
	"Emit a circle of projectiles around you",
}

init_upgrades :: proc() {

	upgrade_sheet = rl.LoadTexture("assets/sprites/spreadshot.png")

	append(&upgrade_choices, Upgrade{.Spread, 3, {0, 0, UPGRADE_SIZE, UPGRADE_SIZE}, {0, 0}, .Idle, false})
	append(&upgrade_choices, Upgrade{.Orbital, 5, {0, 32, UPGRADE_SIZE, UPGRADE_SIZE}, {0, 0}, .Idle, false})
	append(&upgrade_choices, Upgrade{.Spiral, 5, {0, 64, UPGRADE_SIZE, UPGRADE_SIZE}, {0, 0}, .Idle, false})

}

clear_upgrades :: proc() {
	clear(&upgrades)
}

pick_upgrades :: proc() -> [dynamic]Upgrade {

	to_spawn: [dynamic]Upgrade
	choices := make([dynamic]Upgrade, 0)

	for upgrade in upgrade_choices {
		append(&choices, upgrade)
	}

	rand.shuffle(choices[:])

	count := math.clamp((world.loop_number + 1) / 2, 1, 3)

	for i in 0 ..< count {
		append(&to_spawn, choices[i])
	}

	return to_spawn

}

make_upgrades :: proc() {

	prev_entity: Entity
	to_spawn := pick_upgrades()

	for entity in world.levels[world.current_level].entities {
		for &upgrade in to_spawn {
			if entity.type == .Upgrade_Spawn &&
			   upgrades_spawned < len(to_spawn) &&
			   entity.position != prev_entity.position &&
			   !upgrade.has_spawned {


				upgrade.pos = entity.position
				append(&upgrades, upgrade)
				upgrades_spawned += 1
				prev_entity = entity
				upgrade.has_spawned = true

			}
		}

	}
	upgrades_spawned = 0

	clear(&to_spawn)

}

draw_upgrades :: proc() {
	upgrade_info := Upgrade_Info
	for upgrade in upgrades {

		rl.DrawTextureRec(upgrade_sheet, upgrade.draw_coords, get_relative_position(upgrade.pos), rl.WHITE)

		if upgrade.state == .Hover {

			relative_pos := get_relative_position(upgrade.pos)

			rl.DrawText(rl.TextFormat("[E]"), i32(relative_pos.x), i32(relative_pos.y - 10), 5, rl.WHITE)
			rl.DrawText(
				upgrade_info[upgrade.type],
				i32(relative_pos.x),
				i32(relative_pos.y + UPGRADE_SIZE + 10),
				5,
				rl.WHITE,
			)
		}

	}

}

apply_upgrade :: proc(type: Upgrade_Type) {
	attributes := &player_attributes[0]
	switch type {
	case .Spread:
		attributes.shot_amount = 4
		attributes.shot_spread = 30.


	case .Orbital:
		attributes.shot_amount = 4
		attributes.shot_type = .Orbital

	case .Spiral:
		attributes.shot_amount = 10
		attributes.shot_type = .Spiral
	}
}

reset_upgrades :: proc() {
	attributes := &player_attributes[0]
	attributes.shot_amount = 1
	attributes.shot_spread = 22.5
	attributes.shot_type = .Normal
}

update_upgrades :: proc() {

	attributes := &player_attributes[0]
	upgrade_picked := false

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
				upgrade_picked = true
				break
			}
		}
	}
	if upgrade_picked {clear(&upgrades)}
}

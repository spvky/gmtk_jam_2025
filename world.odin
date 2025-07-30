package main

World :: struct {
	first_loop: bool
}

make_world :: proc() -> World {
	return World{ first_loop = true}
}

extends SceneTree
const Main = preload("res://app/bootstrap/bootstrap.tscn")
var failures := 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else: print("PASS: ", message)

func run() -> void:
	var game = Main.instantiate()
	root.add_child(game)
	await process_frame
	game.begin_play()
	var acquired_count := 0
	for stage in range(1, 6):
		game.set_physics_process(false)
		game.player.set_physics_process(false)
		for enemy in game.enemies: enemy.set_physics_process(false)
		check(game.floor_number == 1 and game.stage_number == stage, "same plane room %d" % stage)
		check(is_instance_valid(game.boss) == (stage == 5), "captain only in fifth room")
		check(game.room.outline.size() > 4, "non-rectangular perimeter")
		var start := Vector2i(game.room.entry / 40)
		for destination in [game.room.exit_point] + game.enemies.map(func(enemy): return enemy.position):
			var end := Vector2i(destination / 40)
			check(game.room.navigation.get_id_path(start, end).size() > 1, "reachable exit/enemy in room %d" % stage)
		var a: Vector2 = game.room.outline[1]
		var b: Vector2 = game.room.outline[2]
		var outward := Vector2((b-a).y, -(b-a).x).normalized()
		game.player.position = game.room.nearest_walkable(a.lerp(b, .5) - outward * 70)
		game.player.set_physics_process(true)
		if outward.x > .15: Input.action_press("move_right")
		if outward.x < -.15: Input.action_press("move_left")
		if outward.y > .15: Input.action_press("move_down")
		if outward.y < -.15: Input.action_press("move_up")
		Input.action_press("dash")
		for frame in 45: await physics_frame
		for action in ["move_right", "move_left", "move_down", "move_up", "dash"]: Input.action_release(action)
		game.player.set_physics_process(false)
		check(game.room.contains(game.player.position), "physical dash cannot cross perimeter")
		game.player.position = game.room.exit_point
		check(not game.try_next_floor(), "cannot skip uncleared room")
		for enemy in game.enemies.duplicate(): enemy.take_damage(100000, game.player)
		check(game.portal_open and game.drops.size() == 1, "one reward after complete clear")
		check(not game.try_next_floor(), "reward cannot be abandoned")
		game.drops.clear()
		game.open_choice()
		game.choose_card(game.current_cards[0].id)
		check(game.floor_loot == stage, "plane reward count persists")
		acquired_count = game.abilities.acquired.size()
		check(game.try_next_floor(), "exit advances cleared room")
		await process_frame
	check(game.floor_number == 2 and game.stage_number == 1, "fifth room teleports to next plane first room")
	check(game.floor_loot == 0 and game.abilities.acquired.size() == acquired_count, "new plane resets reward count and keeps build")
	game.restart()
	check(game.floor_number == 1 and game.stage_number == 1, "restart resets both progress counters")
	game.queue_free()
	await process_frame
	print("ROOM FLOW: ", failures, " failures")
	quit(1 if failures else 0)

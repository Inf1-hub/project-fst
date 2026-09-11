extends SceneTree
## Drives the actual input map with normal player health/damage. No instant kills.
const Main = preload("res://app/bootstrap/bootstrap.tscn")
var actions := ["move_up", "move_down", "move_left", "move_right", "weapon_core", "primary_attack", "ability_1", "ability_2", "ability_3", "ability_4", "racial_ability"]


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var game = Main.instantiate()
	root.add_child(game)
	await process_frame
	game.begin_play()
	Engine.max_fps = 0
	var skill_pressed := false
	for frame in 54000:
		await physics_frame
		for action in actions: Input.action_release(action)
		if game.mode == "dead":
			push_error("PLAYTHROUGH: player died after %d kills, frame %d" % [game.kills, frame])
			quit(1)
			return
		if game.mode == "choice":
			game.choose_card(game.current_cards[0].id)
			continue
		if game.floor_number == 2:
			print("PLAYTHROUGH PASS: normal input cleared floor, retained %d build entries, entered floor 2; hp=%d; simulation=%.1fs" % [game.abilities.acquired.size(), game.player.hp, frame / 60.0])
			game.queue_free()
			await process_frame
			quit()
			return
		var target = null
		var distance := INF
		for enemy in game.enemies:
			var candidate: float = game.player.position.distance_to(enemy.position)
			if candidate < distance:
				distance = candidate
				target = enemy
		var destination: Vector2 = target.position if target != null else game.room.exit_point
		if not game.drops.is_empty() and (distance > 250 or target == null):
			destination = game.drops[0]
		var aim := InputEventMouseMotion.new()
		aim.position = game.get_global_transform_with_canvas() * destination
		Input.parse_input_event(aim)
		var movement: Vector2 = game.navigation_direction(game.player.position, destination)
		if target != null and distance < 85 and destination == target.position:
			movement = Vector2.ZERO
		if movement.x > .2: Input.action_press("move_right")
		if movement.x < -.2: Input.action_press("move_left")
		if movement.y > .2: Input.action_press("move_down")
		if movement.y < -.2: Input.action_press("move_up")
		var guard := false
		for enemy in game.enemies:
			var reach: float = game.data.value("boss_attack_range" if enemy.kind == "boss" else "enemy_attack_range")
			if enemy.windup > 0 and enemy.windup < .22 and game.player.position.distance_to(enemy.position) < reach + 20:
				guard = true
				aim = InputEventMouseMotion.new()
				aim.position = game.get_global_transform_with_canvas() * enemy.position
				Input.parse_input_event(aim)
		if guard:
			Input.action_press("weapon_core")
		elif target != null and distance < 130:
			Input.action_press("primary_attack")
		if not guard and not skill_pressed:
			if game.player.counter_time > 0: Input.action_press("ability_2")
			elif distance < 130: Input.action_press("ability_1")
			if game.player.hp < 135:
				Input.action_press("ability_4")
				Input.action_press("racial_ability")
			if distance < 240: Input.action_press("ability_3")
		skill_pressed = not skill_pressed
		if game.portal_open and game.drops.is_empty() and game.player.position.distance_to(game.room.exit_point) < 85:
			var enter := InputEventKey.new()
			enter.keycode = KEY_ENTER
			enter.pressed = true
			Input.parse_input_event(enter)
	push_error("PLAYTHROUGH timed out: position=%s kills=%d enemies=%d hp=%f" % [game.player.position, game.kills, game.enemies.size(), game.player.hp])
	quit(1)

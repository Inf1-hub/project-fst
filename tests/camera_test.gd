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
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	for enemy in game.enemies: enemy.set_physics_process(false)
	game.camera.reset_smoothing()
	await create_timer(.3).timeout
	var before: Vector2 = game.camera.get_screen_center_position()
	var visible_size: Vector2 = root.get_visible_rect().size / game.camera.zoom
	check(game.room.world_size.y > visible_size.y * 2, "camera shows local encounter, not entire room")
	check(not game.camera.top_level and game.camera.position_smoothing_enabled, "camera follows player with smoothing")
	game.player.position = game.room.nearest_walkable(Vector2(1300,1000))
	await create_timer(.7).timeout
	var after: Vector2 = game.camera.get_screen_center_position()
	check(after.distance_to(before) > 250, "camera actually moves between entry and interior")
	var point: Vector2 = game.get_global_transform_with_canvas() * game.player.position
	check(root.get_visible_rect().has_point(point), "player remains within viewport after follow")
	print("CAMERA: viewport world size ", visible_size, " shift ", after.distance_to(before))
	game.queue_free()
	await process_frame
	print("CAMERA TEST: ", failures, " failures")
	quit(1 if failures else 0)


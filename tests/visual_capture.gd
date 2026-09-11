extends SceneTree
const Main = preload("res://app/bootstrap/bootstrap.tscn")
func _initialize() -> void: call_deferred("run")
func capture(id: String) -> void:
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://.local/" + id + ".png")
func run() -> void:
	var game = Main.instantiate()
	root.add_child(game)
	await process_frame
	await create_timer(1.0).timeout
	await capture("title")
	for stage in range(1, 6):
		game.stage_number = stage
		game.load_floor(false)
		game.begin_play()
		game.set_physics_process(false)
		game.player.set_physics_process(false)
		for enemy in game.enemies: enemy.set_physics_process(false)
		game.player.sprite.texture = game.player.back_texture
		game.player.sprite.scale = Vector2.ONE * (110.0 / game.player.back_texture.get_height())
		game.camera.reset_smoothing()
		await create_timer(.2).timeout
		game.hud._process(1)
		await capture("room_%d" % stage)
		if stage == 1:
			game.player.position = game.room.nearest_walkable(Vector2(1750,1650))
			game.camera.reset_smoothing()
			await create_timer(.2).timeout
			await capture("scenery_corridor")
		if stage == 3:
			game.player.position = game.room.nearest_walkable(Vector2(3100,600))
			game.camera.reset_smoothing()
			await create_timer(.2).timeout
			await capture("room_3_center")
			game.player.position = game.room.nearest_walkable(Vector2(4800,2300))
			game.camera.reset_smoothing()
			await create_timer(.2).timeout
			await capture("ranged_position")
	game.open_choice()
	await capture("choice")
	game.choose_card(game.current_cards[0].id)
	game.mode = "paused"
	game.hud.show_pause()
	await capture("pause")
	game.begin_play()
	for enemy in game.enemies.duplicate(): enemy.take_damage(100000, game.player)
	await capture("portal")
	game.queue_free()
	await process_frame
	quit()

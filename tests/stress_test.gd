extends SceneTree
const Main = preload("res://app/bootstrap/bootstrap.tscn")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(1920, 1080)
	var game = Main.instantiate()
	root.add_child(game)
	await process_frame
	game.stage_number = 4
	game.load_floor(false)
	game.begin_play()
	game.player.position = game.room.nearest_walkable(Vector2(900,2700))
	game.camera.reset_smoothing()
	game.player.max_hp = 10000000
	game.player.hp = game.player.max_hp
	while game.enemies.size() < int(game.data.value("enemy_cap")):
		game.spawn_enemy("archer" if game.enemies.size() % 3 == 0 else "soldier", game.player.position + Vector2.from_angle(game.enemies.size() * .7) * 240)
	for enemy in game.enemies: enemy.awake = true
	var report := {"renderer": RenderingServer.get_video_adapter_name(), "resolution": "1920x1080", "uncapped": true, "samples": []}
	for quality in ["low", "medium", "high"]:
		game.set_quality(quality, false)
		Engine.max_fps = 0
		var times: Array[float] = []
		for frame in 900:
			var started := Time.get_ticks_usec()
			game.fx.emit_ring(game.player.position, 80, Color.WHITE)
			game.projectiles.launch(game.player.position + Vector2(-200,0), Vector2.RIGHT, 1)
			await process_frame
			if frame >= 120: times.append(float(Time.get_ticks_usec() - started) / 1000)
		times.sort()
		var total := 0.0
		for value in times: total += value
		var sample := {"quality": quality, "mean_frame_ms": total / times.size(), "p95_frame_ms": times[int(times.size() * .95)], "entities": game.enemies.size(), "static_memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
		report.samples.append(sample)
		print("BENCHMARK: ", JSON.stringify(sample))
	var file := FileAccess.open("res://.local/benchmark.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	game.queue_free()
	await process_frame
	quit()

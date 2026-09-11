extends SceneTree
const Main = preload("res://app/bootstrap/bootstrap.tscn")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else: print("PASS: ",message)
func run() -> void:
	var game = Main.instantiate()
	root.add_child(game)
	await process_frame
	var report := []
	for stage in range(1,6):
		game.stage_number = stage
		game.load_floor(false)
		game.begin_play()
		game.set_physics_process(false)
		game.player.set_physics_process(false)
		for enemy in game.enemies: enemy.set_physics_process(false)
		var room = game.room
		var path: PackedVector2Array = room.navigation.get_point_path(Vector2i(room.entry/40),Vector2i(room.exit_point/40))
		var length := 0.0
		for i in range(1,path.size()): length += path[i].distance_to(path[i-1])
		var direct: float = room.entry.distance_to(room.exit_point)
		var route_points := []
		for at in path: route_points.append([at.x,at.y])
		report.append({"path":route_points,"stage":stage,"shortest_path":length,"direct":direct,"walk_seconds":length/game.data.value("player_speed")})
		check(room.exit_point.x > room.entry.x + 4500,"left to right stage %d" % stage)
		check(length > direct*1.5 and length > 8000,"route requires substantial detour stage %d" % stage)
		check(not game.has_line_of_sight(room.entry,room.exit_point),"cannot cut straight across map")
		check(room.holes.size() >= 2 and room.branches.size() == 2,"two flanking loops around terrain masses")
		for gateway in [Vector2(1750,(room.zones[0].at[1]+room.zones[1].at[1])*.5),Vector2(3900,(room.zones[1].at[1]+room.zones[2].at[1])*.5)]:
			var changed: Array[Vector2i] = []
			var center := Vector2i(gateway/40)
			for y in range(center.y-2,center.y+3):
				for x in range(center.x-6,center.x+7):
					var cell := Vector2i(x,y)
					if not room.navigation.is_point_solid(cell):
						changed.append(cell)
						room.navigation.set_point_solid(cell,true)
			check(room.navigation.get_id_path(Vector2i(room.entry/40),Vector2i(room.exit_point/40)).size()>1,"flank remains passable if main gateway is blocked")
			for cell in changed: room.navigation.set_point_solid(cell,false)
		for supply in room.supplies:
			check(room.navigation.get_point_path(Vector2i(room.entry/40),Vector2i(supply/40)).size()>1,"branch supply is reachable")
		var screen: Dictionary = room.sight_screens[0]
		var r: Array = screen.rect
		var inside := Vector2(r[0]+r[2]*.5,r[1]+r[3]*.5)
		var outside := Vector2(r[0]+r[2]+55,r[1]+r[3]*.5)
		check(game.can_observe(inside,outside) and not game.can_observe(outside,inside),"shelter has one-sided observation")
		check(game.has_line_of_sight(inside,outside) and game.has_line_of_sight(outside,inside),"shelter does not create one-way projectile immunity")
		check(room.observation_clear(outside,outside-Vector2(80,0),100),"close approach reveals shelter")
		var guard = game.enemies[3]
		guard.position = outside
		guard.spawn_position = outside
		guard.awake = true
		game.player.position = inside
		guard.last_known_position = inside
		for step in 15:
			guard.decision_timer = .2
			guard.decide(inside-outside)
		check(not guard.awake,"enemy loses hidden target after memory expires")
		game.player.position = room.supplies[0]
		game.player.hp = 50
		game._physics_process(0)
		var hp: float = game.player.hp
		game._physics_process(0)
		check(room.supplies.size()==1 and hp>50 and game.player.hp==hp,"branch heal is one-use")
	var file := FileAccess.open("res://.local/tactical_layout_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	for item in report: print("ROUTE: stage ",item.stage," length ",item.shortest_path," walk seconds ",item.walk_seconds)
	game.queue_free()
	await process_frame
	print("TACTICAL TEST: ",failures," failures")
	quit(1 if failures else 0)

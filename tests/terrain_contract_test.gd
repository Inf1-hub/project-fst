extends SceneTree
const Main = preload("res://app/bootstrap/bootstrap.tscn")
const Cover = preload("res://content/ruins/cover_cluster.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = Main.instantiate()
	root.add_child(game)
	await process_frame
	for stage in range(1,6):
		game.stage_number = stage
		game.load_floor(false)
		var visual: Array[PackedVector2Array] = []
		var physical: Array[PackedVector2Array] = []
		for actor in game.actors.get_children():
			if actor.get_script() == Cover:
				for item in Cover.pieces(actor.footprint_size):
					var polygon: PackedVector2Array = item.polygon
					for i in polygon.size(): polygon[i] += actor.position
					visual.append(polygon)
		for body in game.room.get_children():
			if body is StaticBody2D:
				var shape = body.get_child(0).shape
				if shape is RectangleShape2D: failures += 1
				if shape is ConvexPolygonShape2D: physical.append(shape.points)
		for polygon in game.room.obstacle_polygons:
			if not visual.has(polygon) or not physical.has(polygon): failures += 1
			var center := Vector2.ZERO
			for point in polygon: center += point
			center /= polygon.size()
			if game.room.is_walkable(center) or game.has_line_of_sight(center,center+Vector2(500,0)): failures += 1
		# Newly released corners must agree with the navigation margin.
		for rect in game.room.obstacles:
			var center: Vector2 = rect.get_center()
			if not game.room.is_walkable(center,36):
				push_error("Collapse gap not walkable in stage %d" % stage)
				failures += 1
			var across := Vector2(0,rect.size.y*.6) if rect.size.x > rect.size.y else Vector2(rect.size.x*.6,0)
			if not game.room.clear_obstacles(center-across,center+across):
				push_error("Collapse gap retains phantom LOS blocker")
				failures += 1
			for x in range(int(rect.position.x/40),ceili(rect.end.x/40)):
				for y in range(int(rect.position.y/40),ceili(rect.end.y/40)):
					var at := Vector2(x*40+20,y*40+20)
					if game.room.navigation.is_point_solid(Vector2i(x,y)) == game.room.is_walkable(at,48): failures += 1
		for quality in ["low","medium","high"]:
			game.set_quality(quality,false)
			var enabled := 0
			for light in get_nodes_in_group("camp_lights"):
				if light.enabled: enabled += 1
			var budget := 0 if quality=="low" else (4 if quality=="medium" else 8)
			if enabled > budget: failures += 1
		game.set_quality("medium",false)
		var kinds := {}
		var scenery_count := 0
		for actor in game.actors.get_children():
			if actor.get_script() == preload("res://content/ruins/scenery_prop.gd"):
				scenery_count += 1
				kinds[actor.atlas_index] = true
				if game.room.contains(actor.position): failures += 1
			if actor.get_script() == preload("res://content/ruins/perimeter_wall.gd"): failures += 1
		if kinds.size() < 6 or scenery_count < 50: failures += 1
		print("TERRAIN stage ",stage,": ",visual.size()," foundations; ",scenery_count," scenery props / ",kinds.size()," kinds")

	game.queue_free()
	await process_frame
	print("TERRAIN CONTRACT: ",failures," failures")
	quit(1 if failures else 0)

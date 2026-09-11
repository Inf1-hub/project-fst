extends Node2D
## All rooms occupy the same grounded plane. Outline drives art, collision and navigation.
var decoration := 1
var ground: Texture2D
var ground_surface: Sprite2D
var debris: AtlasTexture
var navigation := AStarGrid2D.new()
var obstacles: Array[Rect2] = []
var obstacle_polygons: Array[PackedVector2Array] = []
var obstacle_bounds: Array[Rect2] = []
var outline := PackedVector2Array()
var entry := Vector2.ZERO
var exit_point := Vector2.ZERO
var room_name := ""
var world_size := Vector2(2800,2400)
var safe_points := PackedVector2Array()
var boundaries: Array[PackedVector2Array] = []
var holes: Array[PackedVector2Array] = []
var sight_screens: Array = []
var supplies: Array[Vector2] = []
var zones: Array = []
var branches: Array = []


func _ready() -> void:
	ground = load("res://content/ruins/courtyard_ground_v2.png")
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ground_surface = Sprite2D.new()
	ground_surface.texture = ground
	ground_surface.region_enabled = true
	ground_surface.region_rect = Rect2(0, 0, 10600, 7600)
	ground_surface.centered = false
	ground_surface.position = Vector2(-2200, -1800)
	ground_surface.z_index = -1
	var material := ShaderMaterial.new()
	material.shader = load("res://content/rooms/ground_tone.gdshader")
	ground_surface.material = material
	add_child(ground_surface)
	debris = AtlasTexture.new()
	debris.atlas = load("res://content/ruins/ruined_wall.png")
	var dimensions := debris.atlas.get_size()
	debris.region = Rect2(dimensions * Vector2(.31, .49), dimensions * Vector2(.2, .15))


func configure(layout: Dictionary) -> void:
	for child in get_children():
		if child == ground_surface: continue
		remove_child(child)
		child.queue_free()
	room_name = layout.name
	world_size = Vector2(layout.world_size[0],layout.world_size[1])
	entry = Vector2(layout.entry[0], layout.entry[1])
	exit_point = Vector2(layout.exit[0], layout.exit[1])
	boundaries.clear()
	holes.clear()
	supplies.clear()
	zones = layout.zones
	branches = layout.branches
	sight_screens = layout.sight_screens
	for item in layout.supplies: supplies.append(Vector2(item[0],item[1]))
	outline.clear()
	obstacles.clear()
	for point in layout.outline: outline.append(Vector2(point[0], point[1]))
	boundaries.append(outline)
	for raw in layout.holes:
		var hole := PackedVector2Array()
		for point in raw: hole.append(Vector2(point[0],point[1]))
		holes.append(hole)
		boundaries.append(hole)
	add_terrain_mass(layout.terrain_vertices)
	for item in layout.obstacles: obstacles.append(Rect2(item[0], item[1], item[2], item[3]))
	navigation.region = Rect2i(Vector2i.ZERO, Vector2i(world_size / 40))
	navigation.cell_size = Vector2(40, 40)
	navigation.offset = Vector2(20, 20)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	safe_points.clear()
	navigation.fill_solid_region(navigation.region, true)
	for cell in layout.nav_cells:
		var id := Vector2i(cell[0],cell[1])
		navigation.set_point_solid(id, false)
		safe_points.append(Vector2(id.x * 40 + 20, id.y * 40 + 20))
	obstacle_polygons.clear()
	obstacle_bounds.clear()
	for rect in obstacles:
		var anchor := Vector2(rect.get_center().x,rect.end.y)
		for item in preload("res://content/ruins/cover_cluster.gd").pieces(rect.size):
			var polygon: PackedVector2Array = item.polygon
			for i in polygon.size(): polygon[i] += anchor
			obstacle_polygons.append(polygon)
			var bounds := Rect2(polygon[0],Vector2.ZERO)
			for point in polygon: bounds = bounds.expand(point)
			obstacle_bounds.append(bounds)
			var shape := ConvexPolygonShape2D.new()
			shape.points = polygon
			add_collision(shape,Vector2.ZERO)
	# Refresh cells around old envelopes; unchanged cells retain the baked map.
	for rect in obstacles:
		var area := rect.grow(80)
		for x in range(maxi(0,int(area.position.x/40)),mini(navigation.region.end.x,ceili(area.end.x/40))):
			for y in range(maxi(0,int(area.position.y/40)),mini(navigation.region.end.y,ceili(area.end.y/40))):
				navigation.set_point_solid(Vector2i(x,y),not is_walkable(Vector2(x*40+20,y*40+20),48))
	safe_points.clear()
	for y in navigation.region.end.y:
		for x in navigation.region.end.x:
			if not navigation.is_point_solid(Vector2i(x,y)): safe_points.append(Vector2(x*40+20,y*40+20))
	for boundary in boundaries:
		for index in boundary.size():
			var edge := SegmentShape2D.new()
			edge.a = boundary[index]
			edge.b = boundary[(index + 1) % boundary.size()]
			add_collision(edge, Vector2.ZERO)
	queue_redraw()


func add_collision(shape: Shape2D, at: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at
	body.collision_layer = 1
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func is_walkable(at: Vector2, margin: float = 0) -> bool:
	if not contains(at): return false
	if obstacle_at(at,margin): return false
	for boundary in boundaries:
		for index in boundary.size():
			if Geometry2D.get_closest_point_to_segment(at, boundary[index], boundary[(index + 1) % boundary.size()]).distance_to(at) < margin: return false
	return true


func nearest_walkable(at: Vector2) -> Vector2:
	if is_walkable(at, 48): return at
	var nearest := entry
	var distance := INF
	for point in safe_points:
		if point.distance_squared_to(at) < distance:
			distance = point.distance_squared_to(at)
			nearest = point
	return nearest


func contains(at: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(at, outline): return false
	for hole in holes:
		if Geometry2D.is_point_in_polygon(at,hole): return false
	return true


func clear_segment(from: Vector2, to: Vector2) -> bool:
	if not contains(from) or not contains(to): return false
	for boundary in boundaries:
		for index in boundary.size():
			if Geometry2D.segment_intersects_segment(from, to, boundary[index], boundary[(index + 1) % boundary.size()]) != null: return false
	return true


func observation_clear(from: Vector2, to: Vector2, reveal_distance: float) -> bool:
	if from.distance_to(to) < reveal_distance: return true
	for screen in sight_screens:
		var r: Array = screen.rect
		var rect := Rect2(r[0],r[1],r[2],r[3])
		var direction := Vector2(screen.direction[0],screen.direction[1])
		if rect.has_point(to) and not rect.has_point(from): return false
		if rect.has_point(from) and not rect.has_point(to) and (to-from).normalized().dot(direction) <= .2: return false
	return true


func shelter_at(at: Vector2) -> bool:
	for screen in sight_screens:
		var r: Array = screen.rect
		if Rect2(r[0],r[1],r[2],r[3]).has_point(at): return true
	return false


func add_terrain_mass(points: Array) -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	for at in points:
		vertices.append(Vector3(at[0],at[1],0))
		uvs.append(Vector2(at[0],at[1]) / ground.get_size())
		colors.append(Color(.58,.61,.55,1.0))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var terrain := MeshInstance2D.new()
	terrain.mesh = mesh
	terrain.texture = ground
	var earth_material := ShaderMaterial.new()
	earth_material.shader = load("res://content/rooms/terrain_fill.gdshader")
	terrain.material = earth_material
	add_child(terrain)


func clear_movement(from: Vector2, to: Vector2) -> bool:
	# Swept-radius shortcut; a center ray alone catches characters on corners.
	var side := (to-from).normalized().orthogonal() * 36
	if not clear_segment(from, to) or not clear_segment(from + side, to + side) or not clear_segment(from - side, to - side): return false
	for offset in [Vector2.ZERO,side,-side]:
		if not clear_obstacles(from+offset,to+offset): return false
	return true


func obstacle_at(at: Vector2, margin: float = 0) -> bool:
	for index in obstacle_polygons.size():
		if not obstacle_bounds[index].grow(margin).has_point(at): continue
		var polygon := obstacle_polygons[index]
		if Geometry2D.is_point_in_polygon(at,polygon): return true
		for i in polygon.size():
			if Geometry2D.get_closest_point_to_segment(at,polygon[i],polygon[(i+1)%polygon.size()]).distance_to(at) < margin: return true
	return false


func clear_obstacles(from: Vector2, to: Vector2) -> bool:
	if obstacle_at(from) or obstacle_at(to): return false
	for polygon in obstacle_polygons:
		for i in polygon.size():
			if Geometry2D.segment_intersects_segment(from,to,polygon[i],polygon[(i+1)%polygon.size()]) != null: return false
	return true



func _draw() -> void:
	if outline.is_empty(): return
	for at in supplies:
		draw_circle(at,26,Color(.46,.67,.44,.25))
		draw_line(at-Vector2(13,0),at+Vector2(13,0),Color("c4d8a4"),5)
		draw_line(at-Vector2(0,13),at+Vector2(0,13),Color("c4d8a4"),5)

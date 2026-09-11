extends Control
var world


func _draw() -> void:
	if world == null: return
	draw_style_box(make_background(), Rect2(Vector2.ZERO, size))
	var uniform_scale: float = minf(260.0/world.room.world_size.x,300.0/world.room.world_size.y)
	var scale_factor := Vector2.ONE * uniform_scale
	var origin := Vector2(20, 20)
	var polygon := PackedVector2Array()
	for point in world.room.outline: polygon.append(origin + point * scale_factor)
	draw_colored_polygon(polygon, Color("3d4941"))
	polygon.append(polygon[0])
	draw_polyline(polygon, Color("9ca28c"), 2)
	for hole in world.room.holes:
		var points := PackedVector2Array()
		for point in hole: points.append(origin+point*scale_factor)
		draw_colored_polygon(points,Color("151d17"))
	for at in world.room.supplies: draw_circle(origin+at*scale_factor,3,Color("bfd38d"))
	for footprint in world.room.obstacle_polygons:
		var points := PackedVector2Array()
		for point in footprint: points.append(origin+point*scale_factor)
		draw_colored_polygon(points,Color("818c85"))
	for enemy in world.enemies:
		if not enemy.visible: continue
		draw_circle(origin + enemy.position * scale_factor, 5 if enemy.kind == "boss" else 3, Color("c46e59"))
	for at in world.drops:
		draw_circle(origin + at * scale_factor, 4, Color("bbdfb8"))
	draw_circle(origin + world.player.position * scale_factor, 5, Color("a6edf0"))
	if world.portal_open:
		draw_arc(origin + world.room.exit_point * scale_factor, 7, 0, TAU, 12, Color("e9d79d"), 2)


func make_background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.05, .08, .1, .92)
	style.border_color = Color("797966")
	style.set_border_width_all(1)
	return style


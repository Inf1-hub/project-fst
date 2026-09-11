extends Node2D

const GameData = preload("res://data/game_data.gd")
const AbilityBook = preload("res://combat/abilities/ability_book.gd")
const Actor = preload("res://actors/combat_actor.gd")
const Player = preload("res://actors/player/player.gd")
const Room = preload("res://content/rooms/border_room.tscn")
const Dressing = preload("res://content/ruins/fortress_dressing.gd")
const CoverCluster = preload("res://content/ruins/cover_cluster.gd")
const SceneProp = preload("res://content/ruins/scene_prop.gd")
const GroundDecal = preload("res://content/ruins/ground_decal.gd")
const FxPool = preload("res://combat/effects/fx_pool.gd")
const ProjectilePool = preload("res://combat/effects/projectile_pool.gd")
const Sound = preload("res://audio/combat_audio.gd")
const Hud = preload("res://ui/game_hud.gd")

var data = GameData.new()
var abilities = AbilityBook.new(data)
var quality: Dictionary
var rng := RandomNumberGenerator.new()
var room
var actors: Node2D
var player
var boss
var fx
var projectiles
var sound
var hud
var camera: Camera2D
var enemies: Array = []
var drops: Array[Vector2] = []
var cleared: Array[String] = []
var current_cards: Array = []
var mode := "start"
var floor_number := 1
var stage_number := 1
var floor_loot := 0
var kills := 0
var portal_open := false
var message := ""
var message_time := 0.0
var elapsed := 0.0
var seed_value := 0
var capture_frames := 0


func _ready() -> void:
	rng.randomize()
	seed_value = rng.randi()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="): seed_value = int(argument.trim_prefix("--seed="))
	rng.seed = seed_value
	quality = data.qualities.medium
	room = Room.instantiate()
	room.z_index = -10
	add_child(room)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	actors.z_index = 2
	add_child(actors)
	fx = FxPool.new()
	fx.z_index = 5
	fx.configure(self)
	add_child(fx)
	projectiles = ProjectilePool.new()
	projectiles.z_index = 4
	projectiles.configure(self)
	add_child(projectiles)
	sound = Sound.new()
	add_child(sound)
	load_floor(false)
	hud = Hud.new()
	hud.world = self
	add_child(hud)
	var preferences := ConfigFile.new()
	if preferences.load("user://settings.cfg") == OK:
		set_quality(str(preferences.get_value("video", "quality", "medium")), false)
	else:
		set_quality("medium", false)
	hud.show_start()
	print("[逆光] MVP ready. Seed: ", seed_value)
	if "--capture" in OS.get_cmdline_user_args():
		begin_play()
		player.position = room.entry
		capture_frames = 30


func floor_multiplier(key: String) -> float:
	return minf(data.value("floor_scale_cap"), 1 + (floor_number - 1) * data.value(key))


func has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	return room.clear_obstacles(from,to) and room.clear_segment(from,to)


func can_observe(from: Vector2, to: Vector2) -> bool:
	return has_line_of_sight(from,to) and room.observation_clear(from,to,data.value("shelter_reveal_distance"))


func navigation_direction(from: Vector2, to: Vector2) -> Vector2:
	if room.clear_movement(from, to) or (from.distance_to(to) < 100 and has_line_of_sight(from, to)): return (to - from).normalized()
	var start := Vector2i(from / 40).clamp(Vector2i(0, 0), room.navigation.region.end - Vector2i.ONE)
	var end := Vector2i(to / 40).clamp(Vector2i(0, 0), room.navigation.region.end - Vector2i.ONE)
	if room.navigation.is_point_solid(start):
		return (room.nearest_walkable(from) - from).normalized()
	if room.navigation.is_point_solid(end): end = Vector2i(room.nearest_walkable(to) / 40)
	var path: PackedVector2Array = room.navigation.get_point_path(start, end)
	return (path[1] - from).normalized() if path.size() > 1 else (to - from).normalized()


func load_floor(preserve: bool) -> void:
	mode = "loading"
	for actor in actors.get_children():
		actors.remove_child(actor)
		actor.queue_free()
	enemies.clear()
	drops.clear()
	cleared.clear()
	current_cards.clear()
	if stage_number == 1: floor_loot = 0
	portal_open = false
	fx.clear()
	projectiles.clear()
	room.theme = data.themes.get(str(data.rooms[stage_number - 1].id), {})
	room.configure(data.rooms[stage_number - 1])
	boss = null
	add_fortress_dressing()
	var cover_tint: Color = room.theme_color("prop_tint", Color(.85,.87,.86))
	for rect in room.obstacles:
		var wall = CoverCluster.new()
		wall.footprint_size = rect.size
		wall.tint = cover_tint
		wall.position = Vector2(rect.get_center().x, rect.end.y)
		actors.add_child(wall)
	var previous_hp: float = player.hp if preserve and is_instance_valid(player) else data.value("player_hp")
	player = Player.new()
	player.setup(self, "player", room.entry)
	actors.add_child(player)
	if preserve:
		player.hp = minf(player.max_hp, previous_hp + player.max_hp * data.value("floor_heal"))
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * data.value("camera_zoom")
	camera.offset = Vector2.ZERO
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(room.world_size.x)
	camera.limit_bottom = int(room.world_size.y)
	player.add_child(camera)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = data.value("camera_smoothing")
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	camera.drag_left_margin = .08
	camera.drag_right_margin = .08
	camera.drag_top_margin = .08
	camera.drag_bottom_margin = .08
	camera.reset_smoothing()
	var layout: Dictionary = data.rooms[stage_number - 1]
	for index in layout.units.size():
		var at := Vector2(layout.spawns[index][0], layout.spawns[index][1])
		var enemy = spawn_enemy(str(layout.units[index]), at, "%s_%d" % [layout.id, index / int(data.value("encounter_squad_size"))])
		if enemy.kind == "boss": boss = enemy
	mode = "playing" if preserve else "start"
	queue_redraw()


func add_fortress_dressing() -> void:
	var ptint: Color = room.theme_color("prop_tint", Color(.85,.87,.86))
	var wall_a := load("res://content/ruins/ruin_wall_a.png")
	var wall_b := load("res://content/ruins/ruin_wall_b.png")
	# 1) Ruined walls line the play-area edge, forming the corridor instead of a hedge ribbon.
	var serial := 0
	for boundary in room.boundaries:
		var carry := 0.0
		for i in boundary.size():
			var a: Vector2 = boundary[i]
			var b: Vector2 = boundary[(i+1)%boundary.size()]
			var normal := (b-a).normalized().orthogonal()
			if room.contains((a+b)*.5+normal*3): normal = -normal
			var length := a.distance_to(b)
			var step := carry
			while step < length:
				var foot := a.lerp(b,step/length)+normal*46
				if not room.contains(foot):
					var wall = SceneProp.new()
					wall.texture = wall_a if serial%2==0 else wall_b
					wall.art_width = 300.0+float(serial%3)*80.0
					wall.mirrored = serial%2==1
					wall.tint = ptint
					wall.position = foot
					actors.add_child(wall)
					serial += 1
				step += 235
			carry = step-length
	# 2) Fill inaccessible interiors with scenery (backdrop depth; keeps ≥6 kinds / ≥50 props).
	var rng := RandomNumberGenerator.new()
	rng.seed = 731+stage_number
	for y in range(160,3800,260):
		for x in range(160,6400,290):
			var at := Vector2(x+rng.randf_range(-90,90),y+rng.randf_range(-85,85))
			if room.contains(at): continue
			var clearance := 10000.0
			for boundary in room.boundaries:
				for i in boundary.size():
					clearance = minf(clearance,Geometry2D.get_closest_point_to_segment(at,boundary[i],boundary[(i+1)%boundary.size()]).distance_to(at))
			if clearance < 145: continue
			var kind := rng.randi_range(0,5)
			var width := minf(clearance*1.3,rng.randf_range(290,560))
			var fits := true
			for delta in [Vector2(-.5,0),Vector2(.5,0),Vector2(-.5,-1.1),Vector2(.5,-1.1),Vector2(0,-.6)]:
				if room.contains(at+delta*width): fits = false
			if not fits: kind = 5; width = minf(width,200)
			add_scenery(at,kind,width,rng.randf()>.5)
	for screen in room.sight_screens:
		var r: Array = screen.rect
		var shelter := Dressing.new()
		shelter.texture_path = "res://content/ruins/abandoned_camp_v3.png"
		shelter.position = Vector2(r[0]+r[2]*.5,r[1]+r[3])
		shelter.art_size = Vector2(r[2]+80,r[3]+100)
		shelter.tint = Color(1,1,1,.55)
		actors.add_child(shelter)
	dress_route(rng)


func dress_route(rng: RandomNumberGenerator) -> void:
	var layout: Dictionary = data.rooms[stage_number-1]
	# Braziers with warm glow pools along the main path give the corridor light and rhythm.
	var route: Array = layout.get("main_route", [])
	for idx in route.size():
		if idx % 2 == 1: continue
		place_brazier(room.nearest_walkable(Vector2(route[idx][0], route[idx][1])))
	# A tattered war banner marks each tactical anchor.
	for zone in room.zones:
		var at: Vector2 = room.nearest_walkable(Vector2(zone.at[0], zone.at[1]))
		var banner = SceneProp.new()
		banner.texture = load("res://content/ruins/war_banner.png")
		banner.art_width = 92.0
		banner.mirrored = rng.randf() > .5
		banner.position = at + Vector2(84, 6)
		actors.add_child(banner)
	# Barrels and a broken cart add battlefield clutter near the anchors.
	if not room.zones.is_empty():
		var z0: Vector2 = room.nearest_walkable(Vector2(room.zones[0].at[0], room.zones[0].at[1]))
		var barrels = SceneProp.new()
		barrels.texture = load("res://content/ruins/barrels.png")
		barrels.art_width = 150.0
		barrels.position = z0 + Vector2(-96, 40)
		actors.add_child(barrels)
		var last: Dictionary = room.zones[room.zones.size()-1]
		var cart = SceneProp.new()
		cart.texture = load("res://content/ruins/war_cart.png")
		cart.art_width = 260.0
		cart.mirrored = true
		cart.position = room.nearest_walkable(Vector2(last.at[0], last.at[1])) + Vector2(120, -30)
		actors.add_child(cart)
	# Blood and scorch decals on the ground near where fights happen.
	var blood := load("res://content/ruins/decal_blood.png")
	var scorch := load("res://content/ruins/decal_scorch.png")
	for i in layout.spawns.size():
		var at: Vector2 = room.nearest_walkable(Vector2(layout.spawns[i][0], layout.spawns[i][1]))
		var decal = GroundDecal.new()
		decal.texture = blood if i % 3 != 0 else scorch
		decal.art_width = 150.0 + rng.randf_range(0, 70)
		decal.tint = Color(1, 1, 1, 0.62)
		decal.rotation = rng.randf() * TAU
		decal.position = at + Vector2(rng.randf_range(-40, 40), rng.randf_range(-30, 30))
		room.add_child(decal)


var _glow_texture: Texture2D
func glow_texture() -> Texture2D:
	if _glow_texture != null:
		return _glow_texture
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.74, 0.40, 0.85))
	gradient.set_color(1, Color(1.0, 0.55, 0.25, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	_glow_texture = tex
	return tex


func place_brazier(at: Vector2) -> void:
	var glow = GroundDecal.new()
	glow.texture = glow_texture()
	glow.additive = true
	glow.art_width = 540.0
	glow.tint = Color(1, 1, 1, 0.9)
	glow.position = at
	room.add_child(glow)
	var body = SceneProp.new()
	body.texture = load("res://content/ruins/brazier.png")
	body.art_width = 118.0
	body.position = at
	actors.add_child(body)

func add_scenery(at: Vector2, kind: int, width: float, mirror: bool) -> void:
	var prop := preload("res://content/ruins/scenery_prop.gd").new()
	prop.position = at
	prop.atlas_index = kind
	prop.art_width = width
	prop.mirrored = mirror
	prop.tint = room.theme_color("prop_tint", Color(.83,.87,.86))
	actors.add_child(prop)



func spawn_enemy(kind: String, at: Vector2, group_id: String = "adds"):
	if enemies.size() >= int(data.value("enemy_cap")): return null
	var enemy = Actor.new()
	enemy.setup(self, kind, room.nearest_walkable(at), group_id)
	actors.add_child(enemy)
	enemies.append(enemy)
	return enemy


func begin_play() -> void:
	mode = "playing"
	hud.modal.visible = false
	get_viewport().gui_release_focus()


func restart() -> void:
	floor_number = 1
	stage_number = 1
	kills = 0
	abilities = AbilityBook.new(data)
	load_floor(false)
	begin_play()
	notify("再次出发 · 余晖构筑已重置")


func set_quality(id: String, save: bool = true) -> void:
	if not data.qualities.has(id): id = "medium"
	quality = data.qualities[id]
	fx.clear()
	Engine.max_fps = int(quality.max_fps)
	# Compatibility/GLES3 does not support 2D MSAA. Use filtered mipmapped art.
	get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	room.decoration = int(quality.decoration)
	room.queue_redraw()
	if save:
		var preferences := ConfigFile.new()
		preferences.set_value("video", "quality", id)
		preferences.save("user://settings.cfg")
		notify("画质：" + str(quality.name))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		hud.show_performance = not hud.show_performance
	if event.is_action_pressed("pause"):
		if mode == "playing":
			mode = "paused"
			hud.show_pause()
		elif mode == "paused": begin_play()
	if event.is_action_pressed("toggle_map"):
		hud.map_label.visible = not hud.map_label.visible
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER and mode == "playing":
		try_next_floor()


func _physics_process(delta: float) -> void:
	if mode != "playing": return
	elapsed += delta
	for index in range(room.supplies.size()-1,-1,-1):
		if player.position.distance_to(room.supplies[index]) < data.value("pickup_radius"):
			room.supplies.remove_at(index)
			player.hp = minf(player.max_hp,player.hp+player.max_hp*data.value("branch_supply_heal"))
			room.queue_redraw()
			notify("支路补给 · 恢复生命；可由侧道接近远射阵地")
	message_time = maxf(0, message_time - delta)
	for index in range(drops.size() - 1, -1, -1):
		if player.position.distance_to(drops[index]) < data.value("pickup_radius"):
			drops.remove_at(index)
			open_choice()
			break
	queue_redraw()


var observation_clock := 0.0
func _process(_delta: float) -> void:
	observation_clock -= _delta
	if observation_clock <= 0 and is_instance_valid(player):
		observation_clock = .1
		for enemy in enemies:
			enemy.visible = can_observe(player.position,enemy.position)
	if capture_frames > 0:
		capture_frames -= 1
		if capture_frames == 0:
			await RenderingServer.frame_post_draw
			var path := ProjectSettings.globalize_path("res://.local/mvp_capture.png")
			get_viewport().get_texture().get_image().save_png(path)
			print("CAPTURE: ", path)
			get_tree().quit()


func wake_group(id: String) -> void:
	for enemy in enemies:
		if enemy.encounter_id == id: enemy.awake = true


func summon_adds(at: Vector2) -> void:
	var add_count := 0
	for enemy in enemies:
		if enemy.encounter_id == "adds": add_count += 1
	for index in int(data.value("add_count")):
		if add_count >= int(data.value("adds_cap")): break
		var enemy = spawn_enemy("soldier", at + Vector2.from_angle(index * TAU / data.value("add_count")) * data.value("add_spread"))
		if enemy == null: break
		enemy.awake = true
		add_count += 1
	notify("号手召来了增援 · 优先打断或击杀号手")


func enemy_died(enemy) -> void:
	enemies.erase(enemy)
	kills += 1
	if not enemies.is_empty(): return
	portal_open = true
	cleared.append(str(data.rooms[stage_number - 1].id))
	drops.append(room.nearest_walkable(enemy.position))
	notify("战场肃清 · 拾取余晖后前往出口" if stage_number < 5 else "主将倒下 · 拾取余晖后启动位面传送")


func open_choice() -> void:
	var pool: Array = []
	for id in data.afterglows:
		var card: Dictionary = data.afterglows[id].duplicate(true)
		var count: int = abilities.acquired.count(id)
		if count >= int(data.value("afterglow_max_stacks")) or (card.operation == "override" and count > 0):
			card.description = "此辉象已达上限。融入残余之光，恢复部分生命。"
			card.saturated = true
		else:
			card.description += "\n已融入 %d 次" % count
		pool.append(card)
	if pool.is_empty():
		floor_loot += 1
		player.hp = minf(player.max_hp, player.hp + player.max_hp * data.value("floor_heal"))
		notify("余晖已融满 · 残余之光恢复生命")
		return
	current_cards.clear()
	while current_cards.size() < 3 and not pool.is_empty():
		var index := rng.randi_range(0, pool.size() - 1)
		current_cards.append(pool.pop_at(index))
	mode = "choice"
	hud.show_cards(current_cards)


func choose_card(id: String) -> void:
	if mode != "choice": return
	for card in current_cards:
		if card.id == id:
			if card.get("saturated", false):
				player.hp = minf(player.max_hp, player.hp + player.max_hp * data.value("floor_heal"))
			else:
				abilities.acquire(card)
			floor_loot += 1
			current_cards.clear()
			begin_play()
			notify("融入 " + str(card.name))
			sound.play_tone(540, .12, .1)
			return


func try_next_floor() -> bool:
	if mode != "playing" or not drops.is_empty() or not portal_open or player.position.distance_to(room.exit_point) > data.value("portal_radius"):
		return false
	stage_number += 1
	if stage_number > data.rooms.size():
		stage_number = 1
		floor_number += 1
	load_floor(true)
	hud.modal.visible = false
	notify("位面 %d · 第 %d / 5 关 · %s" % [floor_number, stage_number, room.room_name])
	return true


func end_run() -> void:
	mode = "dead"
	hud.show_death()


func notify(text: String) -> void:
	message = text
	message_time = data.value("message_duration")


func ability_feedback(id: String, at: Vector2, direction: Vector2, size: float) -> void:
	player.attack_pose = data.value("fx_lifetime")
	var color := Color("d3d9c5")
	if id == "taunt": color = Color("ab91c7")
	if id in ["bulwark", "rally"]: color = Color("88cbbb")
	if size > 0:
		fx.emit_swing(at, size, direction, float(abilities.definitions[id].arc), color)
	else:
		fx.emit_ring(at, 42, color)
	sound.play_tone(330, .08, .07)


func _draw() -> void:
	if mode == "playing":
		var cursor := get_global_mouse_position()
		draw_arc(cursor, 8, 0, TAU, 16, Color("d3e3da"), 1.5)
		for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			draw_line(cursor + direction * 12, cursor + direction * 17, Color("b6c9c1"), 1.5)
	for at in drops:
		var pulse := sin(elapsed * 3) * 3
		draw_circle(at, 23 + pulse, Color(.5, .75, .7, .13))
		draw_colored_polygon(PackedVector2Array([at + Vector2(0,-14),at + Vector2(8,0),at + Vector2(0,14),at + Vector2(-8,0)]), Color("bee8d3"))
		draw_arc(at, 30, 0, TAU, 24, Color("85bfb4"), 2)
	var at: Vector2 = room.exit_point
	var color := Color("bbccb8") if portal_open else Color("6a6d65")
	if stage_number == 5:
		draw_arc(at, 62, 0, TAU, 48, color, 3)
		if portal_open: draw_arc(at, 46, elapsed, elapsed + PI * 1.6, 32, color, 2)
	else:
		draw_line(at + Vector2(-40, 0), at + Vector2(40, 0), color, 4)
		draw_polyline(PackedVector2Array([at + Vector2(-18, 15), at + Vector2(0,-10), at + Vector2(18,15)]), color, 3)

extends Node2D
var world
var slots: Array[Dictionary] = []
var active_count := 0


func configure(game) -> void:
	world = game
	for index in int(world.data.value("projectile_pool_size")):
		slots.append({"life": 0.0, "at": Vector2.ZERO, "direction": Vector2.ZERO, "damage": 0.0})


func launch(at: Vector2, direction: Vector2, damage: float) -> bool:
	for slot in slots:
		if slot.life <= 0:
			slot.at = at
			slot.direction = direction
			slot.damage = damage
			slot.life = world.data.value("projectile_lifetime")
			return true
	return false


func _physics_process(delta: float) -> void:
	if world == null or world.mode != "playing": return
	active_count = 0
	for slot in slots:
		if slot.life <= 0: continue
		active_count += 1
		slot.life -= delta
		var next: Vector2 = slot.at + slot.direction * world.data.value("projectile_speed") * delta
		var query := PhysicsRayQueryParameters2D.create(slot.at, next, 1)
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			slot.life = 0
			continue
		var nearest := Geometry2D.get_closest_point_to_segment(world.player.position, slot.at, next)
		if nearest.distance_to(world.player.position) < world.player.radius + world.data.value("projectile_radius"):
			# This pool acts as the source at the projectile position for block direction.
			position = slot.at
			world.player.take_damage(slot.damage, self)
			position = Vector2.ZERO
			slot.life = 0
		slot.at = next
	queue_redraw()


func _draw() -> void:
	for slot in slots:
		if slot.life <= 0: continue
		draw_line(slot.at - slot.direction * 20, slot.at, Color("f5bb67"), 3)
		draw_circle(slot.at, 4, Color("efddba"))


func clear() -> void:
	for slot in slots: slot.life = 0
	active_count = 0
	queue_redraw()

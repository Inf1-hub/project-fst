extends CharacterBody2D

const Effects = preload("res://combat/effects/effect_system.gd")
var world
var kind := "soldier"
var encounter_id := ""
var hp := 1.0
var max_hp := 1.0
var radius := 18.0
var speed := 0.0
var damage := 0.0
var facing := Vector2.DOWN
var statuses: Dictionary = {}
var hit_flash := 0.0
var windup := 0.0
var attack_timer := 0.0
var decision_timer := 0.0
var desired_velocity := Vector2.ZERO
var attack_target := Vector2.ZERO
var spawn_position := Vector2.ZERO
var last_known_position := Vector2.ZERO
var unseen_time := 0.0
var awake := false
var phase_two := false
var dead_time := 0.0
var sprite: Sprite2D
var walk_time := 0.0
var attack_pose := 0.0
var front_texture: Texture2D
var back_texture: Texture2D


func setup(game, type: String, at: Vector2, group_id: String = "") -> void:
	world = game
	kind = type
	position = at
	spawn_position = at
	last_known_position = at
	encounter_id = group_id
	radius = world.data.value("boss_radius" if kind == "boss" else "player_radius" if kind == "player" else "enemy_radius")
	max_hp = world.data.value("boss_hp" if kind == "boss" else "enemy_hp")
	speed = world.data.value("enemy_speed")
	damage = world.data.value("boss_damage" if kind == "boss" else "enemy_damage")
	if kind == "archer":
		max_hp = world.data.value("archer_hp")
		speed = world.data.value("archer_speed")
		damage = world.data.value("archer_damage")
	elif kind == "horn":
		max_hp = world.data.value("horn_hp")
	if kind != "player":
		max_hp *= world.floor_multiplier("floor_hp_scale")
		damage *= world.floor_multiplier("floor_damage_scale")
	hp = max_hp
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	add_child(collision)
	collision_layer = 0
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	decision_timer = world.rng.randf_range(0, world.data.value("ai_interval"))
	attack_timer = world.rng.randf_range(0, world.data.value("enemy_attack_cooldown"))
	sprite = Sprite2D.new()
	var texture_path := "res://actors/player/knight.png" if kind == "player" else "res://actors/monsters/archer.png" if kind == "archer" else "res://actors/monsters/soldier.png"
	if kind == "boss": texture_path = "res://actors/monsters/captain_v2.png"
	sprite.texture = load(texture_path)
	front_texture = sprite.texture
	if kind == "player": back_texture = load("res://actors/player/knight_back_v2.png")
	var visual_height := 110.0 * radius / 18.0
	sprite.scale = Vector2.ONE * visual_height / sprite.texture.get_height()
	sprite.position.y = -visual_height * .35
	add_child(sprite)


func _physics_process(delta: float) -> void:
	if world == null or world.mode != "playing":
		return
	Effects.tick(self, delta)
	hit_flash = maxf(0, hit_flash - delta)
	attack_pose = maxf(0, attack_pose - delta)
	walk_time += delta * minf(velocity.length() / 20, 15)
	if sprite != null:
		if kind == "player" and back_texture != null:
			var next_texture := back_texture if facing.y < -.15 else front_texture
			if sprite.texture != next_texture:
				sprite.texture = next_texture
				sprite.scale = Vector2.ONE * (110.0 * radius / 18.0) / sprite.texture.get_height()
		sprite.flip_h = facing.x < 0 if kind == "player" else facing.x > 0
		sprite.rotation = sin(walk_time) * .035 if velocity.length_squared() > 1 else 0.0
		if attack_pose > 0: sprite.rotation += sin(attack_pose * 20) * .12
		sprite.modulate = Color(1.7, 1.7, 1.7) if hit_flash > 0 else Color(.94, .94, .91)
	if hp <= 0:
		dead_time += delta
		modulate.a = maxf(0, 1 - dead_time / world.data.value("corpse_time"))
		if dead_time >= world.data.value("corpse_time"):
			queue_free()
		return
	if kind == "player":
		return
	attack_timer = maxf(0, attack_timer - delta)
	if statuses.has("stun"):
		windup = 0
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var offset: Vector2 = world.player.position - position
	if not awake and offset.length() < world.data.value("archer_post_range" if kind == "archer" else "aggro_range") and world.can_observe(position,world.player.position):
		awake = true
		world.wake_group(encounter_id)
	if kind == "boss" and not phase_two and hp / max_hp < world.data.value("boss_phase_threshold"):
		phase_two = true
		speed *= world.data.value("boss_phase_speed")
		world.notify("百夫长震怒 · 留意红色预警")
	if windup > 0:
		windup -= delta
		if windup <= 0:
			finish_attack()
		velocity = Vector2.ZERO
	elif awake:
		decision_timer -= delta
		if decision_timer <= 0:
			decision_timer = world.data.value("far_ai_interval" if offset.length() > world.data.value("far_ai_distance") else "ai_interval")
			decide(offset)
		velocity = desired_velocity
		if statuses.has("slow"):
			velocity *= statuses.slow.factor
		move_and_slide()
	elif kind == "horn":
		var patrol_at: Vector2 = spawn_position + Vector2(sin(world.elapsed * world.data.value("horn_patrol_rate")) * world.data.value("horn_patrol_radius"), 0)
		velocity = (patrol_at - position).limit_length(speed * world.data.value("horn_patrol_speed_factor"))
		if velocity.length_squared() > 1: facing = velocity.normalized()
		move_and_slide()
	queue_redraw()


func decide(offset: Vector2) -> void:
	if world.can_observe(position,world.player.position):
		last_known_position = world.player.position
		unseen_time = 0
	else:
		unseen_time += decision_timer
		if unseen_time >= world.data.value("sight_memory"):
			awake = false
			desired_velocity = Vector2.ZERO
		else:
			var destination: Vector2 = spawn_position if kind == "archer" else last_known_position
			desired_velocity = world.navigation_direction(position,destination) * speed if position.distance_to(destination) > 45 else Vector2.ZERO
		return
	facing = offset.normalized()
	var reach: float = world.data.value("boss_attack_range" if kind == "boss" else "enemy_attack_range")
	if kind == "archer":
		reach = world.data.value("archer_post_range")
	if kind == "horn":
		reach = world.data.value("aggro_range")
	if offset.length() < reach and attack_timer <= 0 and world.has_line_of_sight(position, world.player.position):
		windup = world.data.value("boss_windup" if kind == "boss" else "enemy_windup")
		if kind == "horn":
			windup = world.data.value("horn_windup")
		attack_target = world.player.position
		desired_velocity = Vector2.ZERO
		return
	desired_velocity = world.navigation_direction(position, world.player.position) * speed
	if kind == "archer" and not statuses.has("taunt") and offset.length() < reach:
		desired_velocity = -facing * speed if offset.length() < reach * world.data.value("archer_retreat_ratio") else Vector2.ZERO
	if kind == "archer" and not statuses.has("taunt") and position.distance_to(spawn_position) > world.data.value("archer_post_leash"):
		desired_velocity = world.navigation_direction(position,spawn_position) * speed
	for other in world.enemies:
		if other == self or other.hp <= 0:
			continue
		var away: Vector2 = position - other.position
		if away.length_squared() < pow(world.data.value("enemy_separation"), 2):
			desired_velocity += away.normalized() * world.data.value("enemy_separation_force")


func finish_attack() -> void:
	attack_pose = world.data.value("fx_lifetime")
	attack_timer = world.data.value("boss_attack_cooldown" if kind == "boss" else "enemy_attack_cooldown")
	if kind == "horn":
		world.summon_adds(position)
		attack_timer = world.data.value("horn_cooldown")
		world.sound.play_tone(180, 0.3, 0.12)
	elif kind == "archer":
		world.projectiles.launch(position, (attack_target - position).normalized(), damage)
	else:
		var reach: float = world.data.value("boss_attack_range" if kind == "boss" else "enemy_attack_range")
		world.fx.emit_ring(position, reach, Color("d65a45"))
		if position.distance_to(world.player.position) <= reach + world.player.radius and world.has_line_of_sight(position, world.player.position):
			world.player.take_damage(damage, self)


func take_damage(amount: float, source) -> void:
	if hp <= 0:
		return
	hp = maxf(0, hp - amount)
	awake = true
	if is_instance_valid(source): last_known_position = source.position
	unseen_time = 0
	hit_flash = world.data.value("invulnerability")
	world.fx.emit_number(position, int(amount), Color("f3dca2"))
	if is_instance_valid(source):
		# Knockback is applied as movement on the next physics tick, not a teleport through walls.
		desired_velocity += (position - source.position).normalized() * world.data.value("hit_push_distance")
	if hp <= 0:
		world.enemy_died(self)
	queue_redraw()


func _draw() -> void:
	if world == null:
		return
	var scale_factor := radius / 18.0
	if int(world.quality.shadows) > 0:
		draw_set_transform(Vector2(0, 12), 0, Vector2(1.3, .48) * scale_factor)
		draw_circle(Vector2.ZERO, 20, Color(0, 0, 0, .28))
	draw_set_transform(Vector2.ZERO)
	if sprite != null:
		draw_combat_indicators()
		return


func draw_combat_indicators() -> void:
	if kind == "player":
		draw_arc(Vector2.ZERO, 23, 0, TAU, 24, Color(.65, .85, .85, .65), 2)
	if kind == "horn":
		draw_colored_polygon(PackedVector2Array([Vector2(-8,-100),Vector2(8,-100),Vector2(13,-78),Vector2(-13,-78)]), Color("d2ad60"))
	if kind != "player" and hp < max_hp and hp > 0:
		draw_rect(Rect2(-radius, -radius * 6 - 10, radius * 2, 4), Color("262b30"))
		draw_rect(Rect2(-radius, -radius * 6 - 10, radius * 2 * hp / max_hp, 4), Color("bd6757"))
	if statuses.has("stun"):
		draw_arc(Vector2(0, -radius - 15), 10, 0, TAU, 12, Color("bb9be8"), 2)
	if windup > 0:
		var reach: float = world.data.value("boss_attack_range" if kind == "boss" else "enemy_attack_range")
		if kind == "archer":
			draw_line(Vector2.ZERO, attack_target - position, Color(1, .35, .25, .65), 2)
		elif kind == "horn":
			draw_arc(Vector2.ZERO, 45, 0, TAU, 24, Color("e7b657"), 4)
		else:
			draw_circle(Vector2.ZERO, reach, Color(.85, .2, .16, .12))
			draw_arc(Vector2.ZERO, reach, 0, TAU, 40, Color("ef7662"), 3)

extends "res://actors/combat_actor.gd"

var shield := 100.0
var blocking := false
var block_age := 0.0
var counter_time := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var dash_charges := 4.0
var dash_direction := Vector2.UP
var invulnerable := 0.0


func _ready() -> void:
	radius = world.data.value("player_radius")
	max_hp = world.data.value("player_hp")
	hp = max_hp
	speed = world.data.value("player_speed")
	shield = world.data.value("shield_max")
	dash_charges = world.data.value("dash_max")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if world.mode != "playing" or hp <= 0:
		return
	world.abilities.tick(delta)
	counter_time = maxf(0, counter_time - delta)
	invulnerable = maxf(0, invulnerable - delta)
	dash_cooldown = maxf(0, dash_cooldown - delta)
	dash_charges = minf(world.data.value("dash_max"), dash_charges + delta / world.data.value("dash_regen"))
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var aim := get_global_mouse_position() - global_position
	if aim.length_squared() > 1:
		facing = aim.normalized()
	var wants_block := Input.is_action_pressed("weapon_core") and shield > 0 and dash_time <= 0
	block_age = block_age + delta if wants_block and blocking else 0.0
	blocking = wants_block
	shield = clampf(shield + delta * (-world.data.value("shield_drain") if blocking else world.data.value("shield_regen")), 0, world.data.value("shield_max"))
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0 and dash_charges >= 1:
		dash_charges -= 1
		dash_time = world.data.value("dash_duration")
		dash_cooldown = world.data.value("dash_cooldown")
		dash_direction = movement if movement != Vector2.ZERO else facing
		world.fx.emit_ring(position, 35, Color("83d2d8"))
	if dash_time > 0:
		dash_time -= delta
		velocity = dash_direction * world.data.value("dash_speed")
	else:
		velocity = movement * speed
		if blocking: velocity *= world.data.value("block_move")
		if statuses.has("haste"): velocity *= statuses.haste.factor
		if statuses.has("slow"): velocity *= statuses.slow.factor
	move_and_slide()
	if not blocking and dash_time <= 0:
		if Input.is_action_pressed("primary_attack"):
			world.abilities.cast("slash", self, world)
		for mapping in [["ability_1", "shield_bash"], ["ability_2", "counter"], ["ability_3", "taunt"], ["ability_4", "bulwark"], ["racial_ability", "rally"]]:
			if Input.is_action_just_pressed(mapping[0]):
				world.abilities.cast(mapping[1], self, world)
	queue_redraw()


func take_damage(amount: float, source) -> void:
	if hp <= 0 or invulnerable > 0 or dash_time > 0:
		return
	if blocking and shield >= world.data.value("block_cost") and facing.dot((source.position - position).normalized()) >= world.data.value("block_dot"):
		shield -= world.data.value("block_cost")
		if block_age <= world.data.value("parry_window"):
			counter_time = world.data.value("counter_window")
			world.notify("精确格挡！按 E 反击")
			world.fx.emit_ring(position, 70, Color("d9f9ea"))
			world.sound.play_tone(760, .09, .1)
			return
		amount *= 1 - world.data.value("block_reduction")
	if statuses.has("guard"):
		amount *= statuses.guard.factor
	hp = maxf(0, hp - amount)
	invulnerable = world.data.value("invulnerability")
	hit_flash = invulnerable
	world.fx.emit_number(position, int(amount), Color("ff8775"))
	world.sound.play_tone(100, .1, .09)
	if hp <= 0:
		world.end_run()


func _draw() -> void:
	super._draw()
	if blocking:
		draw_arc(Vector2.ZERO, 33, facing.angle() - 1.2, facing.angle() + 1.2, 18, Color("9fd9df"), 5)
	if counter_time > 0:
		draw_arc(Vector2.ZERO, 39, 0, TAU, 24, Color("eee7af"), 2)
	if statuses.has("guard"):
		draw_circle(Vector2.ZERO, 34, Color(.25, .7, .75, .12))

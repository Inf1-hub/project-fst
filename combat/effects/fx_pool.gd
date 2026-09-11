extends Node2D
## Fixed-size ring buffer; no transient nodes or per-hit allocations of scenes.
var world
var slots: Array[Dictionary] = []
var cursor := 0


func configure(game) -> void:
	world = game
	for index in int(world.data.value("fx_pool_size")):
		slots.append({"life": 0.0, "at": Vector2.ZERO, "radius": 0.0, "color": Color.WHITE, "text": "", "angle": 0.0, "spread": TAU})


func emit_ring(at: Vector2, size: float, color: Color) -> void:
	push(at, size, color, "")


func emit_number(at: Vector2, amount: int, color: Color) -> void:
	push(at, 0, color, str(amount))


func emit_swing(at: Vector2, size: float, direction: Vector2, arc: float, color: Color) -> void:
	push(at, size, color, "", direction.angle(), acos(clampf(arc, -1, 1)) * 2)


func push(at: Vector2, size: float, color: Color, text: String, angle: float = 0, spread: float = TAU) -> void:
	var cap := mini(slots.size(), int(world.quality.fx_cap))
	cursor = (cursor + 1) % cap
	slots[cursor] = {"life": world.data.value("fx_lifetime"), "at": at, "radius": size, "color": color, "text": text, "angle": angle, "spread": spread}


func _process(delta: float) -> void:
	if world == null or world.mode != "playing": return
	var active := false
	for slot in slots:
		if slot.life > 0:
			slot.life = maxf(0, slot.life - delta)
			active = true
	if active: queue_redraw()


func _draw() -> void:
	if world == null: return
	for slot in slots:
		if slot.life <= 0: continue
		var alpha: float = slot.life / world.data.value("fx_lifetime")
		var color: Color = slot.color
		color.a = alpha
		if slot.text.is_empty():
			draw_arc(slot.at, slot.radius * (1 - alpha * .15), slot.angle - slot.spread * .5, slot.angle + slot.spread * .5, 24, color, 3)
		else:
			draw_string(ThemeDB.fallback_font, slot.at - Vector2(10, 30 * (1 - alpha)), slot.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, color)


func clear() -> void:
	for slot in slots: slot.life = 0
	queue_redraw()

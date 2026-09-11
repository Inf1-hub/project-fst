extends RefCounted

const Effects = preload("res://combat/effects/effect_system.gd")
var definitions: Dictionary
var cooldowns: Dictionary = {}
var acquired: Array[String] = []


func _init(data) -> void:
	definitions = data.skills.duplicate(true)


func tick(delta: float) -> void:
	for key in cooldowns:
		cooldowns[key] = maxf(0, cooldowns[key] - delta)


func cast(id: String, source, world) -> bool:
	if cooldowns.get(id, 0.0) > 0:
		return false
	var ability: Dictionary = definitions[id]
	if ability.requires == "counter" and source.counter_time <= 0:
		world.notify("先精确格挡，再施放反击斩")
		return false
	cooldowns[id] = float(ability.cooldown)
	if ability.requires == "counter":
		source.counter_time = 0
	var targets: Array = []
	if ability.target == "self":
		targets.append(source)
	else:
		for enemy in world.enemies:
			if enemy.hp <= 0:
				continue
			var offset: Vector2 = enemy.position - source.position
			if offset.length() <= float(ability.radius) + enemy.radius and (offset.normalized().dot(source.facing) >= float(ability.arc)) and world.has_line_of_sight(source.position, enemy.position):
				targets.append(enemy)
	for effect in ability.effects:
		if effect.get("recipient", "target") == "source":
			# Healing on attack requires contact; self buffs trigger on cast.
			if effect.system != "heal" or not targets.is_empty():
				Effects.apply(effect, source, source)
		else:
			for target in targets:
				Effects.apply(effect, source, target)
	world.ability_feedback(id, source.position, source.facing, float(ability.radius))
	return true


func acquire(card: Dictionary) -> void:
	var ability: Dictionary = definitions[card.ability]
	if card.operation == "append":
		ability.effects.append_array(card.effects.duplicate(true))
	elif card.operation == "override":
		ability[card.field] = card.value
	acquired.append(card.id)

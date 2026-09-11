extends RefCounted
## Shared atoms for all abilities. No skill-specific rules here.


static func apply(effect: Dictionary, source, target) -> void:
	match effect.system:
		"damage": target.take_damage(float(effect.amount), source)
		"heal": target.hp = minf(target.max_hp, target.hp + float(effect.amount))
		"stun", "slow", "taunt", "guard", "haste":
			var duration := float(effect.duration)
			if target.kind == "boss" and effect.system == "stun":
				duration *= target.world.data.value("boss_stun_factor")
			target.statuses[effect.system] = {"remaining": duration, "factor": float(effect.get("factor", 1.0))}
		_: push_error("Unknown effect system: " + str(effect.system))


static func tick(actor, delta: float) -> void:
	for key in actor.statuses.keys():
		actor.statuses[key].remaining -= delta
		if actor.statuses[key].remaining <= 0:
			actor.statuses.erase(key)

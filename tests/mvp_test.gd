extends SceneTree
const Main = preload("res://app/bootstrap/bootstrap.tscn")
var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)


func run() -> void:
	var game = Main.instantiate()
	root.add_child(game)
	await process_frame
	game.begin_play()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	for enemy in game.enemies: enemy.set_physics_process(false)
	check(game.enemies.size() == 8, "first room spawns three encounter groups")
	check(not game.try_next_floor(), "portal locked before captain dies")
	var target = game.enemies[0]
	game.player.position = target.position + Vector2(0, 50)
	game.player.facing = Vector2.UP
	var before: float = target.hp
	check(game.abilities.cast("shield_bash", game.player, game), "shield bash casts")
	check(target.hp < before and target.statuses.has("stun"), "damage and stun atoms both apply")
	check(not game.abilities.cast("shield_bash", game.player, game), "cooldown prevents repeated cast")
	game.abilities.acquire(game.data.afterglows.frost)
	game.abilities.cast("slash", game.player, game)
	check(target.statuses.has("slow"), "afterglow appends slow to basic attack")
	game.player.facing = (target.position - game.player.position).normalized()
	game.player.blocking = true
	game.player.block_age = 0
	before = game.player.hp
	game.player.take_damage(20, target)
	check(game.player.hp == before and game.player.counter_time > 0, "perfect block opens counter without damage")
	game.player.blocking = false
	game.player.invulnerable = 0
	game.player.dash_time = game.data.value("dash_duration")
	game.player.take_damage(20, target)
	check(game.player.hp == before, "dash grants invulnerability")
	game.player.dash_time = 0
	game.player.take_damage(20, target)
	check(game.player.hp < before, "unguarded contact deals damage")
	game.player.invulnerable = 0
	game.abilities.acquire(game.data.afterglows.reach)
	check(game.abilities.definitions.shield_bash.radius == 200, "override modifies ability data")
	check(game.data.skills.shield_bash.radius == 125, "runtime edits do not mutate source data")
	for enemy in game.enemies.duplicate(): enemy.take_damage(100000, game.player)
	check(game.portal_open and game.drops.size() == 1, "clear room unlocks exit and drops one afterglow")
	game.drops.clear()
	game.open_choice()
	check(game.mode == "choice" and game.current_cards.size() == 3, "three-way choice pauses combat")
	var chosen: String = game.current_cards[0].id
	game.choose_card(chosen)
	check(game.mode == "playing" and chosen in game.abilities.acquired, "selection applies and resumes")
	var count: int = game.abilities.acquired.size()
	game.player.position = game.room.exit_point
	check(game.try_next_floor(), "exit enters next room")
	check(game.floor_number == 1 and game.stage_number == 2 and game.abilities.acquired.size() == count, "same plane next room preserves build")
	check(game.enemies.size() == 8 and not game.portal_open and game.drops.is_empty(), "next room resets encounters and exit")
	for index in 20: game.summon_adds(Vector2(900, 1500))
	check(game.enemies.size() <= 28, "enemy cap survives repeated reinforcements")
	for id in ["low", "medium", "high"]:
		game.set_quality(id, false)
		check(game.quality.id == id and game.enemies.size() >= 8, "quality %s keeps gameplay entities" % id)
	game.player.invulnerable = 0
	game.player.take_damage(100000, game.enemies[0])
	check(game.mode == "dead", "lethal damage opens death screen")
	game.restart()
	check(game.floor_number == 1 and game.abilities.acquired.is_empty() and game.player.hp == game.player.max_hp, "retry resets run and restores health")
	game.queue_free()
	await process_frame
	print("MVP TESTS: ", failures, " failures")
	quit(1 if failures else 0)

extends RefCounted
## CSV is authoritative; callers receive private copies of mutable ability data.

var settings: Dictionary = {}
var skills: Dictionary = {}
var afterglows: Dictionary = {}
var qualities: Dictionary = {}
var encounters: Dictionary = {}
var rooms: Array[Dictionary] = []
var themes: Dictionary = {}


func _init() -> void:
	for row in read_table("mvp_settings"):
		settings[row.id] = float(row.value)
	for table_name in ["skill", "afterglow", "quality", "encounters"]:
		var target: Dictionary
		match table_name:
			"skill": target = skills
			"afterglow": target = afterglows
			"quality": target = qualities
			_: target = encounters
		for row in read_table(table_name):
			target[row.id] = row
	rooms = read_table("rooms")
	assert(rooms.size() == 5)
	for row in read_table("room_themes"):
		themes[row.id] = row
	validate()


func validate() -> void:
	assert(value("enemy_cap") > 0 and value("fx_pool_size") > 0)
	for skill in skills.values():
		assert(skill.cooldown >= 0 and skill.radius >= 0)
		assert(skill.arc >= -1 and skill.arc <= 1)
		assert(skill.target in ["self", "enemy"])
		validate_effects(skill.effects)
	for card in afterglows.values():
		assert(skills.has(card.ability), "Unknown afterglow ability")
		assert(card.operation in ["append", "override"])
		if card.operation == "override":
			assert(skills[card.ability].has(card.field), "Unknown override field")
		validate_effects(card.effects)
	for quality in qualities.values():
		assert(quality.fx_cap > 0 and quality.fx_cap <= value("fx_pool_size"))
	for room in rooms:
		assert(room.outline.size() >= 5 and room.units.size() == room.spawns.size())
		for kind in room.units: assert(kind in ["soldier", "archer", "horn", "boss"])
		assert(themes.has(room.id), "Missing room theme: " + str(room.id))
	for encounter in encounters.values():
		for kind in encounter.units:
			assert(kind in ["soldier", "archer", "horn", "boss"])


func validate_effects(effects: Array) -> void:
	for effect in effects:
		assert(effect.system in ["damage", "heal", "stun", "slow", "taunt", "guard", "haste"], "Unknown effect system")
		if effect.system in ["damage", "heal"]:
			assert(effect.amount >= 0)
		else:
			assert(effect.duration > 0)
		if effect.system in ["slow", "guard"]:
			assert(effect.factor > 0 and effect.factor <= 1)


func read_table(table_name: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open("res://data/%s.csv" % table_name, FileAccess.READ)
	assert(file != null, "Missing data table: " + table_name)
	var columns := file.get_csv_line()
	while not file.eof_reached():
		var cells := file.get_csv_line()
		if cells.size() == 1 and cells[0].is_empty():
			continue
		assert(cells.size() == columns.size(), "Invalid CSV row: " + table_name)
		var row := {}
		for index in columns.size():
			var value: String = cells[index]
			if value.begins_with("[") or value.begins_with("{"):
				row[columns[index]] = JSON.parse_string(value)
			elif value.is_valid_float():
				row[columns[index]] = value.to_float()
			else:
				row[columns[index]] = value
		assert(not row.id in rows.map(func(item): return item.id), "Duplicate data ID")
		rows.append(row)
	return rows


func value(key: String) -> float:
	assert(settings.has(key), "Unknown setting: " + key)
	return settings[key]

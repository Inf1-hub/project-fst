extends CanvasLayer
var world
var title: Label
var objective: Label
var stats: Label
var health: ProgressBar
var shield: ProgressBar
var dash: Label
var notice: Label
var boss_bar: ProgressBar
var boss_title: Label
var skill_labels: Dictionary = {}
var modal: PanelContainer
var modal_box: VBoxContainer
var map_label: Control
var ui_clock := 0.0
var show_performance := false
var ink := Color("d9d7c9")
var accent := Color("bba878")


func _ready() -> void:
	var theme := Theme.new()
	theme.default_font_size = 22
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
	theme.default_font = font
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme
	add_child(root)
	for rect in [Rect2(28, 18, 545, 158), Rect2(1460, 20, 428, 100), Rect2(28, 840, 445, 222)]:
		var backdrop := Panel.new()
		backdrop.position = rect.position
		backdrop.size = rect.size
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.add_theme_stylebox_override("panel", panel_style(Color(.035, .055, .07, .83)))
		root.add_child(backdrop)
	title = label(root, Vector2(48, 32), Vector2(550, 60), "逆 光  /  白石边境", 32)
	objective = label(root, Vector2(48, 100), Vector2(670, 90), "", 21)
	stats = label(root, Vector2(1510, 36), Vector2(370, 60), "", 18)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	notice = label(root, Vector2(500, 220), Vector2(920, 65), "", 27)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_title = label(root, Vector2(625, 45), Vector2(670, 35), "裂城百夫长", 23)
	boss_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar = bar(root, Vector2(600, 88), Vector2(720, 12), Color("a9574d"))
	label(root, Vector2(48, 856), Vector2(430, 40), "人类  /  战士 · 剑盾", 24)
	health = bar(root, Vector2(48, 914), Vector2(370, 24), Color("aa6658"))
	shield = bar(root, Vector2(48, 949), Vector2(370, 12), Color("69949c"))
	dash = label(root, Vector2(48, 979), Vector2(530, 65), "", 18)
	var ids := ["shield_bash", "counter", "taunt", "bulwark", "rally"]
	for index in ids.size():
		var panel := PanelContainer.new()
		panel.position = Vector2(610 + index * 138, 905)
		panel.size = Vector2(122, 102)
		panel.add_theme_stylebox_override("panel", panel_style(Color("202a2f")))
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(panel)
		var text := Label.new()
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.add_theme_font_size_override("font_size", 20)
		panel.add_child(text)
		skill_labels[ids[index]] = text
	label(root, Vector2(610, 1020), Vector2(1000, 40), "WASD 移动    左键 挥斩    右键 格挡    Space 冲刺    Esc 设置    Tab 地图", 17)
	map_label = preload("res://ui/tactical_map.gd").new()
	map_label.world = world
	map_label.position = Vector2(1575, 142)
	map_label.size = Vector2(300, 340)
	map_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(map_label)
	map_label.visible = false
	modal = PanelContainer.new()
	modal.position = Vector2(340, 270)
	modal.size = Vector2(1240, 520)
	modal.add_theme_stylebox_override("panel", panel_style(Color(.055, .075, .09, .98)))
	root.add_child(modal)
	modal_box = VBoxContainer.new()
	modal_box.add_theme_constant_override("separation", 22)
	modal.add_child(modal_box)


func panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("7b7763")
	style.set_border_width_all(1)
	style.set_content_margin_all(24)
	return style


func label(parent: Node, at: Vector2, size: Vector2, text: String, font_size: int) -> Label:
	var item := Label.new()
	item.position = at
	item.size = size
	item.text = text
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", ink)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item


func bar(parent: Node, at: Vector2, size: Vector2, color: Color) -> ProgressBar:
	var item := ProgressBar.new()
	item.position = at
	item.size = size
	item.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var background := StyleBoxFlat.new()
	background.bg_color = Color("20282e")
	item.add_theme_stylebox_override("fill", fill)
	item.add_theme_stylebox_override("background", background)
	parent.add_child(item)
	return item


func _process(delta: float) -> void:
	ui_clock -= delta
	if ui_clock > 0 or world == null or not is_instance_valid(world.player): return
	ui_clock = .1
	var player = world.player
	health.max_value = player.max_hp
	health.value = player.hp
	shield.value = player.shield
	dash.text = "生命 %d / %d     盾压 %d\n冲刺 %d / 4   %s" % [player.hp, player.max_hp, player.shield, int(player.dash_charges), "反击就绪 · E" if player.counter_time > 0 else "精确格挡 → 反击"]
	title.text = "逆光 / 位面 %d · %d/5 %s" % [world.floor_number, world.stage_number, world.room.room_name]
	objective.text = ("拾取余晖 → 出口按 Enter · " + ("传送下一位面" if world.stage_number == 5 else "前往下一关") if world.portal_open else "向右推进 · 剩余 %d 名追光者" % world.enemies.size()) + "\n本层余晖 %d / 5    构筑 %d" % [world.floor_loot, world.abilities.acquired.size()]
	if world.room.shelter_at(player.position): objective.text += "\n遮蔽棚：向右窥视；贴近仍会被发现"
	if show_performance:
		stats.text = "%s   %d FPS\n敌人 %d / 28  ·  弹道 %d" % [world.quality.name, Engine.get_frames_per_second(), world.enemies.size(), world.projectiles.active_count]
	else:
		stats.text = "%s\nTab 战术地图" % world.quality.name
	notice.text = world.message if world.message_time > 0 else ""
	for id in skill_labels:
		var ability: Dictionary = world.abilities.definitions[id]
		var cd: float = world.abilities.cooldowns.get(id, 0.0)
		skill_labels[id].text = "%s  %s\n%s" % [ability.key, ability.name, "%.1fs" % cd if cd > 0 else "就绪"]
		skill_labels[id].modulate = Color("9d9c94") if cd > 0 else ink
	var boss = world.boss
	boss_bar.visible = is_instance_valid(boss) and boss.hp > 0 and boss.awake
	boss_title.visible = boss_bar.visible
	if boss_bar.visible:
		boss_bar.max_value = boss.max_hp
		boss_bar.value = boss.hp
	if map_label.visible: map_label.queue_redraw()


func clear_modal(title_text: String, subtitle: String) -> void:
	for child in modal_box.get_children():
		modal_box.remove_child(child)
		child.queue_free()
	modal.visible = true
	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 38)
	heading.add_theme_color_override("font_color", accent)
	modal_box.add_child(heading)
	var body := Label.new()
	body.text = subtitle
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_box.add_child(body)


func button(text: String, callback: Callable, parent: Node = modal_box) -> Button:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size = Vector2(0, 58)
	item.focus_mode = Control.FOCUS_NONE
	item.pressed.connect(callback)
	parent.add_child(item)
	return item


func show_start() -> void:
	clear_modal("逆 光     /     麦田废壕", "同一片废城，五处相连战场。逐关清剿，第五关击败主将后传送至下一位面。\n人类 · 剑盾  |  清场 → 余晖 → 下一关 → 五关后位面传送")
	button("进入遗迹", world.begin_play)
	quality_buttons()
	var hint := Label.new()
	hint.text = "左键挥斩 · 右键正面格挡 · 在敌人命中前举盾可精确格挡 · E 反击\nQ 盾击控制 · R 挑衅减速 · F 壁垒回复 · C 人类号角 · Space 闪避红圈"
	hint.add_theme_font_size_override("font_size", 20)
	modal_box.add_child(hint)


func quality_buttons() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	modal_box.add_child(row)
	for id in ["low", "medium", "high"]:
		var item := button(world.data.qualities[id].name, func(): world.set_quality(id), row)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func show_pause() -> void:
	clear_modal("休 整", "调整画质即时生效。三档保留相同敌人、碰撞和攻击预警。")
	quality_buttons()
	button("继续战斗", world.begin_play)
	button("重新开始本局", world.restart)
	button("退出游戏", func(): get_tree().quit())


func show_cards(cards: Array) -> void:
	clear_modal("辉 象     /     选择一项余晖", "一种光，三条路径。融入一项，其余熄灭。选择期间战斗暂停。")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	modal_box.add_child(row)
	for card in cards:
		var item := button("", func(): world.choose_card(card.id), row)
		item.custom_minimum_size = Vector2(375, 260)
		var color := Color("bba878")
		match card.color:
			"cyan": color = Color("8bbabf")
			"green": color = Color("99bca0")
			"white": color = Color("dddfcc")
		var normal := panel_style(Color("17252b"))
		normal.border_color = color.darkened(.4)
		var hover := panel_style(Color("26353a"))
		hover.border_color = color
		item.add_theme_stylebox_override("normal", normal)
		item.add_theme_stylebox_override("hover", hover)
		item.add_theme_stylebox_override("pressed", hover)
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + side, 24)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(margin)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 18)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(box)
		for text in [card.grade, card.name, card.description]:
			var line := Label.new()
			line.text = str(text)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.add_theme_color_override("font_color", color if text == card.name else ink)
			line.add_theme_font_size_override("font_size", 25 if text == card.name else 20)
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(line)


func show_death() -> void:
	clear_modal("光未熄灭，逆光者倒下了", "抵达第 %d 层 · 击败 %d 名追光者 · 融入 %d 项余晖\n重试会清空本局构筑。" % [world.floor_number, world.kills, world.abilities.acquired.size()])
	button("重新出发", world.restart)
	button("退出游戏", func(): get_tree().quit())

extends SceneTree
## Catch baked backgrounds and unexpectedly large runtime art imports.


func _initialize() -> void:
	var cutouts := [
		"res://content/ruins/rubble_bank_v3.png",
		"res://content/ruins/field_barricade_v3.png",
		"res://content/ruins/abandoned_camp_v3.png",
		"res://actors/player/knight_back_v2.png",
		"res://actors/monsters/captain_v2.png"
	]
	var failures := 0
	for path in cutouts:
		var texture := load(path) as Texture2D
		if texture == null:
			push_error("Missing art: " + path)
			failures += 1
			continue
		var pixels := texture.get_image()
		if pixels.detect_alpha() == Image.ALPHA_NONE:
			push_error("Cutout has no transparency: " + path)
			failures += 1
		if maxi(texture.get_width(), texture.get_height()) > 1024:
			push_error("Import exceeds texture size budget: " + path)
			failures += 1
		print("ART: ", path, " ", texture.get_size(), " alpha=", pixels.detect_alpha())
	print("ART CONTRACT: ", failures, " failures")
	quit(1 if failures else 0)

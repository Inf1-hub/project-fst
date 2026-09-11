extends CanvasLayer
## A single static backdrop behind the 2D playfield; no 3D geometry or lights.


func _ready() -> void:
	layer = -20
	var landscape := TextureRect.new()
	landscape.texture = load("res://content/ruins/distant_ruins_v2.png")
	landscape.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	landscape.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	landscape.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	landscape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	landscape.modulate = Color(.84, .87, .9)
	add_child(landscape)

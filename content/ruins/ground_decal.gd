extends Node2D
## Flat ground decal (blood, scorch) or additive light pool. Centered on position, lies on the ground.
var texture: Texture2D
var art_width := 300.0
var tint := Color(1, 1, 1, 0.85)
var additive := false

func _ready() -> void:
	if additive:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat

func _draw() -> void:
	if texture == null:
		return
	var size: Vector2 = texture.get_size() * (art_width / texture.get_size().x)
	draw_texture_rect(texture, Rect2(-size * 0.5, size), false, tint)

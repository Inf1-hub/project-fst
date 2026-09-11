extends Node2D
## High-quality bottom-anchored prop with a soft contact shadow so it reads as grounded.
## Anchor (position) is the ground contact; art is drawn upward from there. Y-sorted with actors.
var texture: Texture2D
var art_width := 300.0
var mirrored := false
var tint := Color(1, 1, 1)
var shadow := true
var shadow_scale := 1.0
var shadow_alpha := 0.34

func _draw() -> void:
	if texture == null:
		return
	var size: Vector2 = texture.get_size() * (art_width / texture.get_size().x)
	if shadow:
		draw_set_transform(Vector2(size.x * 0.03, -3), 0, Vector2(1.0, 0.30))
		draw_circle(Vector2.ZERO, art_width * 0.44 * shadow_scale, Color(0, 0, 0, shadow_alpha))
		draw_set_transform(Vector2.ZERO)
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if mirrored else 1, 1))
	draw_texture_rect(texture, Rect2(Vector2(-size.x * 0.5, -size.y), size), false, tint)
	draw_set_transform(Vector2.ZERO)

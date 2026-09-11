extends Node2D
## Reusable painted silhouette. Sorting anchor is its bottom contact line.
var texture_path := ""
var art_size := Vector2(400, 900)
var mirrored := false
var tint := Color.WHITE
var texture: Texture2D


func _ready() -> void:
	texture = load(texture_path)


func _draw() -> void:
	if texture == null: return
	draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if mirrored else 1, 1))
	draw_texture_rect(texture, Rect2(Vector2(-art_size.x * .5, -art_size.y), art_size), false, tint)
	draw_set_transform(Vector2.ZERO)

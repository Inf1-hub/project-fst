extends Node2D
var wall_width := 200.0
var texture: Texture2D


func _ready() -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://content/ruins/ruined_wall.png")
	# Ignore source padding through an atlas region; preserve the source image.
	var dimensions := atlas.atlas.get_size()
	atlas.region = Rect2(dimensions * Vector2(.018, .186), dimensions * Vector2(.963, .563))
	texture = atlas


func _draw() -> void:
	draw_rect(Rect2(-wall_width * .5 + 12, -35, wall_width, 45), Color(0, 0, 0, .26))
	if texture != null:
		draw_texture_rect(texture, Rect2(-wall_width * .5 - 10, -125, wall_width + 20, 135), false, Color("bdc5c9"))

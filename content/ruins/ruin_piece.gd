extends Node2D
## Upright painted masonry; Y anchor is the front ground contact, not image center.
var extent := Vector2(180,65)
var variant := 0
var tint := Color(.85,.87,.86)
var wall: AtlasTexture
var rubble: Texture2D
func _ready() -> void:
	wall = AtlasTexture.new()
	wall.atlas = load("res://content/ruins/ruined_wall.png")
	var regions := [Rect2(.018,.186,.35,.563),Rect2(.34,.34,.31,.39),Rect2(.69,.186,.29,.563)]
	var region: Rect2 = regions[variant % regions.size()]
	wall.region = Rect2(region.position*wall.atlas.get_size(),region.size*wall.atlas.get_size())
	rubble = load("res://content/ruins/rubble_bank_v3.png")
func _draw() -> void:
	if wall == null: return
	# Alpha cutouts retain broken tops and detached chips. No rectangular shadow pass.
	var width := extent.x
	var height := width * .65 + extent.y * .30
	var bank_height := width / 3.0
	# Soft contact shadow so the masonry reads as sitting on the ground, not pasted on.
	draw_set_transform(Vector2(0, -2), 0, Vector2(1.0, 0.34))
	draw_circle(Vector2.ZERO, width * 0.60, Color(0, 0, 0, 0.16))
	draw_circle(Vector2.ZERO, width * 0.42, Color(0, 0, 0, 0.24))
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect(rubble,Rect2(-width*.53,-bank_height,width*1.06,bank_height),false,tint)
	if variant == 1:
		# Fallen core uses a compact section, preserving its natural image aspect.
		var source := Rect2(rubble.get_size()*Vector2(.28,.08),rubble.get_size()*Vector2(.40,.84))
		draw_texture_rect_region(rubble,Rect2(-width*.5,-width*.70,width,width*.70),source,tint)
	if variant != 1:
		draw_set_transform(Vector2.ZERO,0,Vector2(-1 if variant % 2 else 1,1))
		draw_texture_rect(wall,Rect2(-width*.48,-height-extent.y*.18,width*.96,height),false,tint)
		draw_set_transform(Vector2.ZERO)

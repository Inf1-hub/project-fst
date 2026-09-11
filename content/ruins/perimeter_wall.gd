extends Node2D
## Project a wall volume from its ground contact into the fixed game camera.
var front_a := Vector2.ZERO
var front_b := Vector2.ZERO
var back_a := Vector2.ZERO
var back_b := Vector2.ZERO
var height_a := 80.0
var height_b := 80.0
var stone: Texture2D
var rubble: Texture2D
var rubble_here := false
var pier_here := false
var pier: AtlasTexture

func _ready() -> void:
	stone = load("res://content/ruins/ruined_wall.png")
	rubble = load("res://content/ruins/rubble_bank_v3.png")
	pier = AtlasTexture.new()
	pier.atlas = stone
	pier.region = Rect2(stone.get_size()*Vector2(.025,.235),stone.get_size()*Vector2(.145,.485))

func surface(points: PackedVector2Array, region: Rect2, tint: Color) -> void:
	var uv := PackedVector2Array([region.position,Vector2(region.end.x,region.position.y),region.end,Vector2(region.position.x,region.end.y)])
	# Edge-on vertical faces have zero area; skip rather than triangulating them.
	for indices in [[0,1,2],[0,2,3]]:
		if absf((points[indices[1]]-points[indices[0]]).cross(points[indices[2]]-points[indices[0]])) < .01: continue
		draw_polygon(PackedVector2Array([points[indices[0]],points[indices[1]],points[indices[2]]]),PackedColorArray([tint,tint,tint]),PackedVector2Array([uv[indices[0]],uv[indices[1]],uv[indices[2]]]),stone)

func _draw() -> void:
	if stone == null: return
	var up_a := Vector2(-height_a*.18,-height_a)
	var up_b := Vector2(-height_b*.18,-height_b)
	# Back and front share exactly the same raised edge as the cap.
	surface(PackedVector2Array([back_a+up_a,back_b+up_b,back_b,back_a]),Rect2(.18,.50,.16,.22),Color(.40,.43,.44))
	surface(PackedVector2Array([front_a+up_a,front_b+up_b,front_b,front_a]),Rect2(.18,.50,.16,.22),Color(.68,.72,.74))
	surface(PackedVector2Array([back_a+up_a,back_b+up_b,front_b+up_b,front_a+up_a]),Rect2(.51,.39,.11,.09),Color(.78,.82,.80))
	if pier_here:
		var foot := (front_a+back_a)*.5
		draw_texture_rect(pier,Rect2(foot-Vector2(23,height_a+24),Vector2(46,height_a+24)),false,Color(.83,.87,.86))
	if rubble_here:
		var crest := (front_a+back_a+front_b+back_b)*.25-Vector2(0,(height_a+height_b)*.5)
		draw_texture_rect(rubble,Rect2(crest-Vector2(43,12),Vector2(86,28)),false,Color(.84,.87,.82))
		var at := (front_a+front_b)*.5
		draw_texture_rect(rubble,Rect2(at-Vector2(58,27),Vector2(116,39)),false,Color(.76,.80,.76))

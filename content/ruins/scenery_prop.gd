extends Node2D
## Immutable atlas cutouts; scale remains uniform and props share one texture.
var atlas_index := 0
var art_width := 300.0
var mirrored := false
var tint := Color(.83,.87,.86)
var image_texture: AtlasTexture
static var textures: Array[AtlasTexture] = []
func _ready() -> void:
	if textures.is_empty():
		var sheet: Texture2D = load("res://content/ruins/scenery_atlas_v1.png")
		var pixels := sheet.get_image()
		for index in 6:
			var cell := Rect2i((index%3)*512,(index/3)*512,512,512)
			var used := pixels.get_region(cell).get_used_rect()
			var texture := AtlasTexture.new()
			texture.atlas = sheet
			texture.region = Rect2(cell.position+used.position,used.size)
			textures.append(texture)
	image_texture = textures[atlas_index]
func _draw() -> void:
	if image_texture == null: return
	var art_size := image_texture.get_size()*(art_width/image_texture.get_width())
	draw_set_transform(Vector2.ZERO,0,Vector2(-1 if mirrored else 1,1))
	draw_texture_rect(image_texture,Rect2(Vector2(-art_size.x*.5,-art_size.y),art_size),false,tint)

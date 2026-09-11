extends Node2D
var variant := 0
var art_width := 300.0
var mirrored := false
var texture: AtlasTexture
static var textures: Array[AtlasTexture] = []
static var glow: GradientTexture2D
static var live_count := 0
func _ready() -> void:
	live_count += 1
	if textures.is_empty():
		var sheet: Texture2D = load("res://content/ruins/camp_atlas_v1.png")
		for region in [Rect2(0,0,910,525),Rect2(925,0,611,620),Rect2(0,527,1050,497),Rect2(1080,630,456,394)]:
			var sprite := AtlasTexture.new()
			sprite.atlas = sheet
			sprite.region = region
			textures.append(sprite)
	texture = textures[variant]
	if variant == 3: z_index = 1
	if variant == 1 or variant == 3:
		if glow == null:
			glow = GradientTexture2D.new()
			glow.width = 256
			glow.height = 256
			glow.fill = GradientTexture2D.FILL_RADIAL
			glow.fill_from = Vector2(.5,.5)
			glow.fill_to = Vector2(.5,0)
			glow.gradient = Gradient.new()
			glow.gradient.set_color(0,Color(1,1,1,.85))
			glow.gradient.set_color(1,Color(0,0,0,0))
		var light := PointLight2D.new()
		light.texture = glow
		light.texture_scale = 2.2
		light.color = Color("ffaf59")
		light.energy = .7
		light.shadow_enabled = false
		light.position = Vector2((-1 if mirrored else 1)*art_width*(-.25 if variant==1 else 0),-art_width*.24)
		light.add_to_group("camp_lights")
		add_child(light)
func _draw() -> void:
	if texture == null: return
	var size := texture.get_size()*(art_width/texture.get_width())
	draw_set_transform(Vector2.ZERO,0,Vector2(-1 if mirrored else 1,1))
	draw_texture_rect(texture,Rect2(Vector2(-size.x*.5,-size.y),size),false,Color(.92,.94,.96))

func _exit_tree() -> void:
	live_count -= 1
	if live_count == 0:
		textures.clear()
		glow = null

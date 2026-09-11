extends Node2D
## Layout rectangles are placement envelopes, never physical shapes.
const Piece = preload("res://content/ruins/ruin_piece.gd")
var footprint_size := Vector2(300,100)

static func pieces(size: Vector2) -> Array:
	var result: Array = []
	# Authored collapse compositions: two broken ends, a displaced fallen block.
	# Coordinates describe masses and empty space; there is no row/column fill.
	var composition: Array
	if size.y > size.x * 1.5:
		composition = [Vector4(.42,.13,.80,.24),Vector4(.76,.27,.36,.10),Vector4(.62,.86,.72,.25)]
	elif size.x > size.y * 1.5:
		composition = [Vector4(.13,.45,.26,.83),Vector4(.26,.74,.10,.36),Vector4(.86,.61,.25,.70)]
	else:
		composition = [Vector4(.23,.28,.42,.38),Vector4(.65,.67,.48,.35),Vector4(.82,.39,.15,.18)]
	for index in composition.size():
		var mass: Vector4 = composition[index]
		var extent := Vector2(mass.z,mass.w)*size
		var at := Vector2(-size.x*.5,-size.y)+Vector2(mass.x,mass.y)*size
		var polygon := PackedVector2Array()
		for unit in [Vector2(-.50,-.16),Vector2(-.28,-.46),Vector2(.19,-.50),Vector2(.43,-.29),Vector2(.50,.13),Vector2(.21,.44),Vector2(-.24,.50),Vector2(-.46,.20)]:
			polygon.append(at+unit*extent)
		result.append({"at":at,"size":extent,"polygon":polygon,"variant":index})

	return result

func _ready() -> void:
	y_sort_enabled = true
	for item in pieces(footprint_size):
		var piece := Piece.new()
		piece.position = item.at + Vector2(0,item.size.y*.5)
		piece.extent = item.size
		piece.variant = item.variant
		add_child(piece)

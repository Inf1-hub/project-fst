extends Node2D
## Per-level accent landmark: a leaning war standard with a tattered cloth.
## Gives each room a themed focal color and readable spatial marker. Y-sorted with actors.
var accent := Color(.6,.2,.15)
var banner_height := 150.0
var lean := 0.12

func _draw() -> void:
	var h := banner_height
	var top := Vector2(-h * lean, -h)
	# Contact shadow so the standard reads as grounded, not floating.
	draw_set_transform(Vector2(4, 2), 0, Vector2(1.0, .34))
	draw_circle(Vector2.ZERO, 22, Color(0, 0, 0, .26))
	draw_set_transform(Vector2.ZERO)
	# Pole.
	var pole := Color(.16, .15, .14)
	draw_line(Vector2.ZERO, top, pole, 4.0)
	draw_line(top, top + Vector2(0, 6), pole, 4.0)
	# Finial.
	draw_circle(top + Vector2(0, -3), 5.0, accent.lerp(Color(1, 1, 1), .25))
	# Tattered cloth hanging from the top.
	var w := 48.0
	var drop := 78.0
	var o := top + Vector2(2, 2)
	var cloth := PackedVector2Array([
		o,
		o + Vector2(w, 6),
		o + Vector2(w, drop * .72),
		o + Vector2(w * .72, drop * .58),
		o + Vector2(w * .5, drop * .86),
		o + Vector2(w * .28, drop * .56),
		o + Vector2(0, drop),
	])
	draw_colored_polygon(cloth, accent)
	# Inner emblem stripe for a little depth.
	draw_line(o + Vector2(w * .5, 8), o + Vector2(w * .5, drop * .6), accent.darkened(.28), 3.0)

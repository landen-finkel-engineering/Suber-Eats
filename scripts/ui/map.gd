extends Control

const LEVELS = 10
const CIRCLE = preload("res://assets/graphics/unorganized/level-circle.png")


func _draw():
	for i in range(1, LEVELS):
		draw_line(spot(i - 1), spot(i), Color.WHITE, 1)
	for i in LEVELS:
		draw_texture_rect(CIRCLE, Rect2(spot(i) - Vector2(5, 5), Vector2(10, 10)), false, Color("5fef7f") if Progress.done(i + 1) else Color("5f9fff"))


func spot(i):
	var col = i % 5 if i < 5 else 4 - i % 5
	return Vector2(7 + col * 15, 30 if i >= 5 else 8)

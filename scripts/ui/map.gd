extends Control

const LEVELS = 10


func _draw():
	for i in range(1, LEVELS):
		draw_line(spot(i - 1), spot(i), Color.WHITE, 1)
	for i in LEVELS:
		draw_circle(spot(i), 4, Color("3fbf5f") if Progress.done(i + 1) else Color("3f7fdf"))


func spot(i):
	var col = i % 5 if i < 5 else 4 - i % 5
	return Vector2(7 + col * 15, 30 if i >= 5 else 8)

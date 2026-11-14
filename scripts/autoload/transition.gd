extends CanvasLayer

var fade = ColorRect.new()


func _ready():
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	fade.color = Color.BLACK
	fade.size = Vector2(320, 180)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 0
	add_child(fade)


func go(path):
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.15)
	await tween.finished
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(path)
	create_tween().tween_property(fade, "modulate:a", 0.0, 0.2)

extends Button


func _ready():
	resized.connect(func(): pivot_offset = size / 2)
	pivot_offset = size / 2
	mouse_entered.connect(pop.bind(1.08))
	mouse_exited.connect(pop.bind(1.0))
	button_down.connect(pop.bind(0.92))
	button_up.connect(pop.bind(1.0))


func pop(to):
	create_tween().tween_property(self, "scale", Vector2.ONE * to, 0.08)

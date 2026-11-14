@tool
extends Area2D

# Where Rico delivers the food.

@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			$Sprite2D.texture = value


func _ready():
	$Sprite2D.texture = texture
	if Engine.is_editor_hint() or texture == null:
		return
	var shape = CircleShape2D.new()
	shape.radius = min(texture.get_width(), texture.get_height()) * 0.45
	$CollisionShape2D.shape = shape

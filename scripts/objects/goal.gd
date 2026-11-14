@tool
extends Area2D

@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			$Sprite2D.texture = value


func _ready():
	$Sprite2D.texture = texture
	if texture and not Engine.is_editor_hint():
		$CollisionShape2D.shape = CircleShape2D.new()
		$CollisionShape2D.shape.radius = min(texture.get_width(), texture.get_height()) * 0.7

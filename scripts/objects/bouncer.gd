@tool
extends StaticBody2D

# Anything Rico can bounce off. Every bounce counts as an object used.
# bounce: 1 = same speed back, lower = loses speed, higher = springy
# friction: 1 = slides freely, lower = more grip

@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			$Sprite2D.texture = value
@export var bounce := 0.6
@export var friction := 0.8
# use a circle hit box (planets) instead of a box
@export var round := false


func _ready():
	$Sprite2D.texture = texture
	if Engine.is_editor_hint() or texture == null:
		return
	var size = texture.get_size()
	if round:
		$CollisionShape2D.shape = CircleShape2D.new()
		$CollisionShape2D.shape.radius = min(size.x, size.y) / 2
	else:
		$CollisionShape2D.shape = RectangleShape2D.new()
		$CollisionShape2D.shape.size = size

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
# optional second picture, swaps back and forth (platform thrusters)
@export var texture2: Texture2D
@export var bounce := 0.6
@export var friction := 0.8
# pixels at the bottom of the picture Rico goes through (thruster flames)
@export var flame_height := 0.0


func _ready():
	$Sprite2D.texture = texture
	if Engine.is_editor_hint() or texture == null:
		return
	var shape = RectangleShape2D.new()
	shape.size = texture.get_size() - Vector2(0, flame_height)
	$CollisionShape2D.shape = shape
	$CollisionShape2D.position.y = -flame_height / 2


func _process(_delta):
	if texture2 and not Engine.is_editor_hint():
		$Sprite2D.texture = texture2 if Time.get_ticks_msec() / 150 % 2 else texture

@tool
extends Area2D

# Pulls Rico in when he's inside pull_radius. Touching the middle = reset.

@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			$Sprite2D.texture = value
@export var pull_radius := 70.0
@export var strength := 600.0
@export var core_radius := 7.0


func _ready():
	$Sprite2D.texture = texture
	if not Engine.is_editor_hint():
		$CollisionShape2D.shape = CircleShape2D.new()
		$CollisionShape2D.shape.radius = pull_radius


func _process(delta):
	if not Engine.is_editor_hint():
		$Sprite2D.rotation += delta


func pull(point, delta):
	var dir = global_position - point
	var dist = dir.length()
	if dist > pull_radius or dist == 0:
		return Vector2.ZERO
	return dir / dist * strength * (1 - dist / pull_radius) * delta


func swallows(point, rico_radius):
	return global_position.distance_to(point) < core_radius + rico_radius

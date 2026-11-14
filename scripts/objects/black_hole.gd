extends Area2D

@export var pull_radius := 70.0
@export var strength := 600.0
@export var core_radius := 10.0


func _ready():
	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = pull_radius


func _process(delta):
	$Sprite2D.rotation += delta


func pull(point, delta):
	var dir = global_position - point
	if dir.length() > pull_radius or dir == Vector2.ZERO:
		return Vector2.ZERO
	return dir.normalized() * strength * (1 - dir.length() / pull_radius) * delta


func swallows(point, rico_radius):
	return global_position.distance_to(point) < core_radius + rico_radius

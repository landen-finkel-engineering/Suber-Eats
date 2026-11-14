extends Area2D

@export var pull_radius := 170.0
@export var strength := 1200.0
@export var core_radius := 14.0


func _ready():
	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = pull_radius


func _process(delta):
	$Sprite2D.rotation += delta * 0.8


func affect(rico, delta):
	var dir = global_position - rico.global_position
	if dir.length() < pull_radius:
		rico.velocity += dir.normalized() * strength * (1 - dir.length() / pull_radius) * delta


func swallows(rico):
	return global_position.distance_to(rico.global_position) < core_radius + rico.radius

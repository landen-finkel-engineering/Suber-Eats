extends AnimatableBody2D

@export var travel := Vector2(120, 0)
@export var trip_time := 3.0
@export var lift := 110.0

var bounce := 1.0
var friction := 0.95
var kick := 360.0
var start_pos: Vector2
var t := 0.0
var dead := false


func _ready():
	start_pos = position
	$Beam.frame_changed.connect(center_beam)
	center_beam()


func center_beam():
	$Beam.offset.x = -$Beam.sprite_frames.get_frame_texture("default", $Beam.frame).get_width() / 2.0


func _physics_process(delta):
	if not dead:
		t += delta
		position = start_pos + travel * (0.5 - 0.5 * cos(t / trip_time * TAU))


func affect(rico, delta):
	if dead or not Rect2(-13, 0, 26, 47).has_point($Beam.to_local(rico.global_position)):
		return
	var target = Vector2((global_position.x - rico.global_position.x) * 4, -lift)
	rico.velocity = rico.velocity.move_toward(target, 900 * delta)
	rico.velocity.y -= rico.gravity * delta


func destroy():
	dead = true
	$CollisionShape2D.set_deferred("disabled", true)
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2(1.6, 0.2), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)


func reset():
	dead = false
	t = 0
	position = start_pos
	scale = Vector2.ONE
	modulate.a = 1
	$CollisionShape2D.set_deferred("disabled", false)

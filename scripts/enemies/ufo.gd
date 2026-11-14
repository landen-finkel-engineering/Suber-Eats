extends AnimatableBody2D

@export var travel := Vector2(80, 0)
@export var trip_time := 3.0
@export var suck := 900.0

var bounce = Bouncer.TRAMPOLINE_BOUNCE[Bouncer.Trampoline.GREEN]
var friction := 0.95
var start_pos: Vector2
var t := 0.0


func _ready():
	start_pos = position
	$Beam.frame_changed.connect(center_beam)
	center_beam()


func center_beam():
	$Beam.offset.x = -$Beam.sprite_frames.get_frame_texture("default", $Beam.frame).get_width() / 2.0


func _physics_process(delta):
	t += delta
	position = start_pos + travel * (0.5 - 0.5 * cos(t / trip_time * TAU))


func reset():
	t = 0
	position = start_pos


func pull(point, delta):
	if not Rect2(-13, 0, 26, 47).has_point($Beam.to_local(point)):
		return Vector2.ZERO
	return (global_position - point).normalized() * suck * delta

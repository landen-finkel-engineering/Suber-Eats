@tool
extends Node2D

# Floats from where you put it to (position + travel) and back.
# The beam underneath captures Rico. Landing on the UFO defeats it.

signal defeated

@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			$Sprite2D.texture = value
@export var travel := Vector2(80, 0)
@export var trip_time := 3.0
@export var boost := 260.0

var start_pos: Vector2
var t := 0.0
var dead := false


func _ready():
	$Sprite2D.texture = texture
	if Engine.is_editor_hint():
		return
	start_pos = position
	if texture:
		var shape = RectangleShape2D.new()
		shape.size = texture.get_size()
		$Hitbox/CollisionShape2D.shape = shape
		$Beam.position.y = texture.get_height() / 2.0
	$Hitbox.body_entered.connect(_on_hitbox_body_entered)
	$Beam.body_entered.connect(_on_beam_body_entered)


func _physics_process(delta):
	if Engine.is_editor_hint() or dead:
		return
	t += delta
	position = start_pos + travel * (0.5 - 0.5 * cos(t / trip_time * TAU))


func reset():
	dead = false
	t = 0
	position = start_pos
	show()
	$Hitbox.set_deferred("monitoring", true)
	$Beam.set_deferred("monitoring", true)


func _on_hitbox_body_entered(body):
	if dead or body.name != "Rico" or not body.flying():
		return
	dead = true
	hide()
	$Hitbox.set_deferred("monitoring", false)
	$Beam.set_deferred("monitoring", false)
	body.velocity.y = -boost
	defeated.emit()


func _on_beam_body_entered(body):
	if not dead and body.name == "Rico" and body.flying():
		body.capture(self)

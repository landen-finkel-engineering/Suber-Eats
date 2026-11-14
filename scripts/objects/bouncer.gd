@tool
class_name Bouncer
extends StaticBody2D

enum Trampoline { NONE, RED, GREEN, BLUE }
const TRAMPOLINE_BOUNCE = [0.0, 1.5, 1.8, 2.2]

@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			$Sprite2D.texture = value
@export var trampoline := Trampoline.NONE:
	set(value):
		trampoline = value
		if is_node_ready():
			tint()
@export var bounce := 0.6
@export var friction := 0.8
@export var round := false


func _ready():
	$Sprite2D.texture = texture
	tint()
	if Engine.is_editor_hint() or texture == null:
		return
	if trampoline:
		bounce = TRAMPOLINE_BOUNCE[trampoline]
	var size = texture.get_size()
	if round:
		$CollisionShape2D.shape = CircleShape2D.new()
		$CollisionShape2D.shape.radius = min(size.x, size.y) / 2
	else:
		$CollisionShape2D.shape = RectangleShape2D.new()
		$CollisionShape2D.shape.size = size


func tint():
	$Sprite2D.material = null
	if trampoline > Trampoline.RED:
		$Sprite2D.material = ShaderMaterial.new()
		$Sprite2D.material.shader = preload("res://scripts/objects/hue.gdshader")
		$Sprite2D.material.set_shader_parameter("hue", 120.0 * (trampoline - 1))

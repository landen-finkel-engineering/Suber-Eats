@tool
class_name Bouncer
extends StaticBody2D

@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready():
			$Sprite2D.texture = value
@export var bounce := 0.6
@export var friction := 0.8
@export var kick := 0.0
@export var round := false


func _ready():
	$Sprite2D.texture = texture
	if Engine.is_editor_hint() or texture == null:
		return
	if texture.resource_path.get_file().begins_with("trampoline"):
		bounce = 1.6
		kick = 400.0
	var used = Rect2(texture.get_image().get_used_rect())
	if round:
		$CollisionShape2D.shape = CircleShape2D.new()
		$CollisionShape2D.shape.radius = min(used.size.x, used.size.y) / 2
	else:
		$CollisionShape2D.shape = RectangleShape2D.new()
		$CollisionShape2D.shape.size = used.size
	$CollisionShape2D.position = used.get_center() - texture.get_size() / 2


func hit():
	$Sprite2D.scale = Vector2(1.15, 0.8) if kick else Vector2(1.06, 0.94)
	create_tween().tween_property($Sprite2D, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

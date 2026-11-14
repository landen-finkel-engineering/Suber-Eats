@tool
class_name DeliveryPlanet
extends Area2D
## The planet Rico delivers the food to. One per level.

## The picture. Leave empty for a placeholder planet.
@export var texture: Texture2D:
	set(value):
		texture = value
		_rebuild()
## Hit radius in pixels. 0 = from the picture size.
@export var radius := 0.0:
	set(value):
		radius = value
		_rebuild()
@export var placeholder_color := Color(0.3, 0.6, 1.0):
	set(value):
		placeholder_color = value
		queue_redraw()

var _shape_node: CollisionShape2D
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("level_planet")
	_rebuild()


func get_radius() -> float:
	if radius > 0.0:
		return radius
	if texture != null:
		return minf(texture.get_width(), texture.get_height()) * 0.45
	return 12.0


func _rebuild() -> void:
	if _shape_node == null:
		_shape_node = CollisionShape2D.new()
		add_child(_shape_node, false, Node.INTERNAL_MODE_FRONT)
		_sprite = Sprite2D.new()
		add_child(_sprite, false, Node.INTERNAL_MODE_FRONT)
	var circle := CircleShape2D.new()
	circle.radius = get_radius()
	_shape_node.shape = circle
	_sprite.texture = texture
	queue_redraw()


func _draw() -> void:
	if texture != null:
		return
	var r := get_radius()
	draw_circle(Vector2.ZERO, r, placeholder_color)
	draw_circle(Vector2(-r * 0.3, -r * 0.25), r * 0.25, placeholder_color.lightened(0.25))
	var ring := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		ring.append(Vector2(cos(a) * r * 1.5, sin(a) * r * 0.35))
	draw_polyline(ring, placeholder_color.lightened(0.4), 1.0)

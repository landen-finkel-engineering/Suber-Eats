@tool
class_name LevelObject
extends StaticBody2D
## A solid thing Rico bounces off. Every bounce off one of these counts as an "object used".
##
## Kind sets sensible defaults:
##   SOLID   normal bounce, some grip
##   BOUNCE  springy, Rico leaves faster than he arrived
##   SLIDE   barely bounces, no grip, Rico slides along it
## You can still change Bounciness and Friction by hand afterwards.

enum Kind { SOLID, BOUNCE, SLIDE }

const PRESETS := {
	Kind.SOLID: {"bounciness": 0.6, "friction": 0.8, "color": Color(0.45, 0.5, 0.65)},
	Kind.BOUNCE: {"bounciness": 1.3, "friction": 0.95, "color": Color(1.0, 0.35, 0.6)},
	Kind.SLIDE: {"bounciness": 0.15, "friction": 1.0, "color": Color(0.5, 0.9, 1.0)},
}

@export var kind: Kind = Kind.SOLID:
	set(value):
		var changed := kind != value
		kind = value
		# Only apply presets when someone changes the kind in the editor, not when loading.
		if changed and is_node_ready():
			bounciness = PRESETS[kind].bounciness
			friction = PRESETS[kind].friction
		_rebuild()
## The picture. Leave empty to show a colored placeholder box.
@export var texture: Texture2D:
	set(value):
		texture = value
		_rebuild()
## 1.0 = bounces back at the same speed, below 1 loses speed, above 1 gains speed.
@export_range(0.0, 2.0, 0.05) var bounciness := 0.6
## 1.0 = no slowdown when sliding along it, lower = more grip.
@export_range(0.0, 1.0, 0.05) var friction := 0.8

@export_group("Collision")
## Use a circle instead of a box (good for asteroids).
@export var round_shape := false:
	set(value):
		round_shape = value
		_rebuild()
## Size of the hit box. (0, 0) = same size as the picture.
@export var collision_size := Vector2.ZERO:
	set(value):
		collision_size = value
		_rebuild()
## Move the hit box, e.g. to leave out the thrusters under a platform.
@export var collision_offset := Vector2.ZERO:
	set(value):
		collision_offset = value
		_rebuild()
## Placeholder size when there's no picture.
@export var placeholder_size := Vector2(48, 8):
	set(value):
		placeholder_size = value
		_rebuild()

var _shape_node: CollisionShape2D
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("level_objects")
	_rebuild()


## The size of the hit box in pixels.
func get_box_size() -> Vector2:
	if collision_size != Vector2.ZERO:
		return collision_size
	if texture != null:
		return texture.get_size()
	return placeholder_size


func _rebuild() -> void:
	if _shape_node == null:
		_shape_node = CollisionShape2D.new()
		add_child(_shape_node, false, Node.INTERNAL_MODE_FRONT)
		_sprite = Sprite2D.new()
		add_child(_sprite, false, Node.INTERNAL_MODE_FRONT)
	var box := get_box_size()
	if round_shape:
		var circle := CircleShape2D.new()
		circle.radius = minf(box.x, box.y) / 2.0
		_shape_node.shape = circle
	else:
		var rect := RectangleShape2D.new()
		rect.size = box
		_shape_node.shape = rect
	_shape_node.position = collision_offset
	_sprite.texture = texture
	queue_redraw()


func _draw() -> void:
	if texture != null:
		return
	var color: Color = PRESETS[kind].color
	if round_shape:
		draw_circle(Vector2.ZERO, minf(placeholder_size.x, placeholder_size.y) / 2.0, color)
	else:
		draw_rect(Rect2(-placeholder_size / 2.0, placeholder_size), color)
	if kind == Kind.BOUNCE:
		draw_line(Vector2(-placeholder_size.x / 2.0, -placeholder_size.y / 2.0),
			Vector2(placeholder_size.x / 2.0, -placeholder_size.y / 2.0), Color.WHITE, 1.0)

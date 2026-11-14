@tool
class_name BlackHole
extends Node2D
## Pulls Rico in when he's within Pull Radius. Touching the center resets the attempt.
## Doesn't count as an object used.

## The picture. Leave empty for a placeholder swirl.
@export var texture: Texture2D:
	set(value):
		texture = value
		_rebuild()
## How far away the pull reaches, in pixels.
@export var pull_radius := 70.0:
	set(value):
		pull_radius = value
		queue_redraw()
## How hard it pulls (stronger near the center).
@export var strength := 600.0
## Touching this close to the center = sucked in.
@export var core_radius := 7.0:
	set(value):
		core_radius = value
		queue_redraw()

var _sprite: Sprite2D
var _spin := 0.0


func _ready() -> void:
	add_to_group("level_black_holes")
	_rebuild()


func _rebuild() -> void:
	if _sprite == null:
		_sprite = Sprite2D.new()
		add_child(_sprite, false, Node.INTERNAL_MODE_FRONT)
	_sprite.texture = texture
	queue_redraw()


## Extra speed this black hole gives Rico this frame.
func pull_on(point: Vector2, delta: float) -> Vector2:
	var to_center := global_position - point
	var distance := to_center.length()
	if distance >= pull_radius or distance < 0.001:
		return Vector2.ZERO
	return to_center / distance * strength * (1.0 - distance / pull_radius) * delta


## extra = the size of whatever is being checked (Rico's radius), so touching the edge counts.
func is_swallowing(point: Vector2, extra := 0.0) -> bool:
	return global_position.distance_to(point) < core_radius + extra


func _process(delta: float) -> void:
	_spin += delta * 2.0
	if _sprite:
		_sprite.rotation = _spin
	if texture == null:
		queue_redraw()


func _draw() -> void:
	# Pull range (faint ring).
	draw_arc(Vector2.ZERO, pull_radius, 0, TAU, 48, Color(0.7, 0.4, 1.0, 0.25), 1.0)
	if texture != null:
		return
	draw_circle(Vector2.ZERO, core_radius * 2.0, Color(0.35, 0.1, 0.55))
	for i in 3:
		var a := _spin + i * TAU / 3.0
		draw_arc(Vector2.ZERO, core_radius * 1.6, a, a + 1.6, 8, Color(0.85, 0.6, 1.0), 1.0)
	draw_circle(Vector2.ZERO, core_radius, Color.BLACK)

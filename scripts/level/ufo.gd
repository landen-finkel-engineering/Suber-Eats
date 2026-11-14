@tool
class_name UFO
extends Node2D
## Floats back and forth. Its tractor beam (below it) captures Rico and resets the attempt.
## Bouncing on the UFO itself defeats it and gives Rico a boost (doesn't count as an object).
## In the editor the dotted line shows its path.

signal defeated

## The picture. Leave empty for a placeholder saucer.
@export var texture: Texture2D:
	set(value):
		texture = value
		_rebuild()
## How far it travels from where you placed it (and back).
@export var travel := Vector2(80, 0):
	set(value):
		travel = value
		queue_redraw()
## Seconds for one full trip there and back.
@export var trip_time := 3.0
## Size of the UFO's body hit box. (0, 0) = picture size.
@export var body_size := Vector2.ZERO:
	set(value):
		body_size = value
		_rebuild()
@export var beam_length := 50.0:
	set(value):
		beam_length = value
		_rebuild()
@export var beam_width := 14.0:
	set(value):
		beam_width = value
		_rebuild()
## Upward speed Rico gets from bouncing on it.
@export var boost_speed := 260.0

var is_defeated := false
var _start := Vector2.ZERO
var _time := 0.0
var _sprite: Sprite2D
var _hitbox: Area2D
var _hitbox_shape: CollisionShape2D
var _beam: Area2D
var _beam_shape: CollisionShape2D


func _ready() -> void:
	add_to_group("level_ufos")
	_rebuild()
	if Engine.is_editor_hint():
		return
	_start = position
	_hitbox.body_entered.connect(_on_hitbox_body_entered)
	_beam.body_entered.connect(_on_beam_body_entered)


func get_body_size() -> Vector2:
	if body_size != Vector2.ZERO:
		return body_size
	if texture != null:
		return texture.get_size()
	return Vector2(24, 10)


func _rebuild() -> void:
	if _sprite == null:
		_beam = Area2D.new()
		_beam_shape = CollisionShape2D.new()
		_beam.add_child(_beam_shape)
		add_child(_beam, false, Node.INTERNAL_MODE_FRONT)
		_hitbox = Area2D.new()
		_hitbox_shape = CollisionShape2D.new()
		_hitbox.add_child(_hitbox_shape)
		add_child(_hitbox, false, Node.INTERNAL_MODE_FRONT)
		_sprite = Sprite2D.new()
		add_child(_sprite, false, Node.INTERNAL_MODE_FRONT)
	var body := get_body_size()
	var hit_rect := RectangleShape2D.new()
	hit_rect.size = body
	_hitbox_shape.shape = hit_rect
	var beam_rect := RectangleShape2D.new()
	beam_rect.size = Vector2(beam_width, beam_length)
	_beam_shape.shape = beam_rect
	_beam_shape.position = Vector2(0, body.y / 2.0 + beam_length / 2.0)
	_sprite.texture = texture
	queue_redraw()


func reset() -> void:
	is_defeated = false
	_time = 0.0
	position = _start
	scale = Vector2.ONE
	modulate.a = 1.0
	show()
	_hitbox.set_deferred("monitoring", true)
	_beam.set_deferred("monitoring", true)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or is_defeated:
		return
	_time += delta
	var trip := 0.5 - 0.5 * cos(_time / maxf(trip_time, 0.1) * TAU)
	position = _start + travel * trip + Vector2(0, sin(_time * 4.0) * 1.5)


func _on_hitbox_body_entered(body: Node) -> void:
	if is_defeated or not (body is Rico) or not body.is_flying():
		return
	is_defeated = true
	_hitbox.set_deferred("monitoring", false)
	_beam.set_deferred("monitoring", false)
	body.ufo_boost(boost_speed)
	defeated.emit()
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2(1.4, 0.2), 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(hide)


func _on_beam_body_entered(body: Node) -> void:
	if is_defeated or not (body is Rico) or not body.is_flying():
		return
	body.capture(self)


func _draw() -> void:
	var body := get_body_size()
	# Beam
	var top := body.y / 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-beam_width * 0.3, top), Vector2(beam_width * 0.3, top),
		Vector2(beam_width / 2.0, top + beam_length), Vector2(-beam_width / 2.0, top + beam_length),
	]), Color(0.6, 1.0, 0.6, 0.25))
	if Engine.is_editor_hint() and travel != Vector2.ZERO:
		draw_dashed_line(Vector2.ZERO, travel, Color(1, 1, 1, 0.5), 1.0, 3.0)
		draw_arc(travel, 3.0, 0, TAU, 12, Color(1, 1, 1, 0.5), 1.0)
	if texture != null:
		return
	draw_circle(Vector2(0, -body.y * 0.25), body.y * 0.45, Color(0.6, 0.9, 1.0, 0.85))
	var saucer := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		saucer.append(Vector2(cos(a) * body.x / 2.0, sin(a) * body.y * 0.3 + body.y * 0.1))
	draw_colored_polygon(saucer, Color(0.7, 0.72, 0.78))

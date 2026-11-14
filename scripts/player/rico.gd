class_name Rico
extends CharacterBody2D
## Rico, the Suber delivery alien. The Level creates him at the StartPoint.
## Pinch (or hold the mouse), pull back, let go: he stretches, then launches.
## After that, physics only: gravity and bounces.

signal launched
## Rico bounced off a level object (only real bounces, not sliding or rolling).
signal bounced(body: Node)
signal delivered
signal lost(reason: String)

enum State { READY, HOLDING, FLYING, DONE }

const SCREEN_SIZE := Vector2(320, 180)
## Rico's picture is looked for in these places, first one found wins.
const SPRITE_PATHS := [
	"res://assets/graphics/sprites/characters/rico.png",
	"res://assets/graphics/unorganized/rico1.png",
]

@export_group("Launch")
@export var max_pull := 60.0
@export var launch_power := 6.0
@export var gravity := 300.0
@export var min_pull_to_launch := 6.0
## Aim is taken this many seconds before you let go (opening your fingers wiggles your hand).
@export var release_lookback := 0.1
@export var must_pinch_near_rico := false
@export var grab_radius := 30.0
@export var hand_lost_grace := 0.4
## The part of the camera picture (0-1) that covers the whole screen.
@export var hand_area := Rect2(0.15, 0.15, 0.7, 0.7)

@export_group("Look")
@export var max_stretch := 0.6
@export var max_squash := 0.3
@export var pull_back_amount := 0.35

@export_group("Bouncing")
@export var min_bounce_speed := 40.0

var state := State.READY
var tracker: HandTracker
var use_hand := true
var pull := Vector2.ZERO
var anchor := Vector2.ZERO
var pointer := {}
var start_position := Vector2.ZERO
## Size of Rico's hit circle (set from his picture).
var radius := 5.0

var _visual: Node2D
var _hold_source := ""
var _history: Array[Dictionary] = []
var _clock := 0.0
var _was_pinching := {"HAND": false, "MOUSE": false}
var _hand_lost_for := 0.0
var _stuck_for := 0.0
var _last_bounce_body: Object = null
var _last_bounce_time := -1.0
var _tween: Tween


func _ready() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	var texture: Texture2D = null
	for path in SPRITE_PATHS:
		if ResourceLoader.exists(path):
			texture = load(path)
			break
	if texture != null:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		_visual.add_child(sprite)
		radius = minf(texture.get_width(), texture.get_height()) * 0.38
	else:
		var placeholder := Node2D.new()
		placeholder.set_script(preload("res://scripts/objects/placeholder_shape.gd"))
		placeholder.shape = 2  # ALIEN
		placeholder.size = Vector2(10, 10)
		placeholder.color = Color(0.45, 0.9, 0.45)
		_visual.add_child(placeholder)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)


func is_flying() -> bool:
	return state == State.FLYING


func reset_to(point: Vector2) -> void:
	if _tween:
		_tween.kill()
	start_position = point
	position = point
	state = State.READY
	velocity = Vector2.ZERO
	pull = Vector2.ZERO
	scale = Vector2.ONE
	_visual.transform = Transform2D.IDENTITY
	_stuck_for = 0.0
	show()


## Launch straight away with a given speed (used by tests and tools).
func launch(launch_velocity: Vector2) -> void:
	velocity = launch_velocity
	state = State.FLYING
	_stuck_for = 0.0
	_last_bounce_body = null
	_snap_forward()
	launched.emit()


func fail(reason: String) -> void:
	if state != State.FLYING:
		return
	state = State.DONE
	hide()
	lost.emit(reason)


func capture(by: Node2D) -> void:
	if state != State.FLYING:
		return
	state = State.DONE
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "global_position", by.global_position, 0.5)
	_tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.5)
	_tween.chain().tween_callback(func() -> void: lost.emit("Captured by a UFO!"))


func deliver(planet: Node2D) -> void:
	if state != State.FLYING:
		return
	state = State.DONE
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "global_position", planet.global_position, 0.35)
	_tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.35)
	_tween.chain().tween_callback(func() -> void: delivered.emit())


func ufo_boost(speed: float) -> void:
	velocity.y = -speed
	_stuck_for = 0.0


# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_clock += delta
	pointer = _read_pointer()
	match state:
		State.READY:
			var just_pinched: bool = pointer.pinching and not _was_pinching[pointer.source]
			if just_pinched and (not must_pinch_near_rico or pointer.pos.distance_to(start_position) <= grab_radius):
				state = State.HOLDING
				_hold_source = pointer.source
				anchor = pointer.pos
				pull = Vector2.ZERO
				_history.clear()
				_hand_lost_for = 0.0
		State.HOLDING:
			_update_holding(delta)
		State.FLYING:
			_fly(delta)
	_was_pinching[pointer.source] = pointer.pinching


func _read_pointer() -> Dictionary:
	if use_hand and tracker != null and tracker.hand_visible:
		var p := ((tracker.hand_position - hand_area.position) / hand_area.size).clamp(Vector2.ZERO, Vector2.ONE)
		return {"source": "HAND", "pos": p * SCREEN_SIZE, "pinching": tracker.is_pinching}
	return {"source": "MOUSE", "pos": get_global_mouse_position(),
		"pinching": Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)}


func _update_holding(delta: float) -> void:
	if _hold_source == "HAND" and (tracker == null or not tracker.hand_visible):
		_hand_lost_for += delta
		if _hand_lost_for > hand_lost_grace:
			_cancel_hold()
		return
	_hand_lost_for = 0.0
	if pointer.source != _hold_source:
		return
	if pointer.pinching:
		pull = (pointer.pos - anchor).limit_length(max_pull)
		_history.append({"time": _clock, "pull": pull})
		while _history.size() > 2 and _history[0].time < _clock - 0.5:
			_history.pop_front()
		var amount := pull.length() / max_pull
		position = start_position + pull * pull_back_amount
		if pull.length() > 0.5:
			_visual.transform = _stretch_along(pull.angle(), 1.0 + max_stretch * amount, 1.0 - max_squash * amount)
	else:
		var aim := _pull_at(_clock - release_lookback)
		if aim.length() < min_pull_to_launch:
			_cancel_hold()
		else:
			launch(-aim * launch_power)


func _cancel_hold() -> void:
	state = State.READY
	pull = Vector2.ZERO
	position = start_position
	_visual.transform = Transform2D.IDENTITY


func _pull_at(time: float) -> Vector2:
	if _history.is_empty():
		return pull
	var chosen: Vector2 = _history[0].pull
	for entry in _history:
		if entry.time <= time:
			chosen = entry.pull
	return chosen


func _fly(delta: float) -> void:
	velocity.y += gravity * delta
	var hit := move_and_collide(velocity * delta)
	if hit:
		_bounce(hit)
	_visual.rotation += velocity.x * delta * 0.02
	if velocity.length() < 10.0:
		_stuck_for += delta
		if _stuck_for > 1.0:
			fail("Rico got stuck!")
	else:
		_stuck_for = 0.0


func _bounce(hit: KinematicCollision2D) -> void:
	var body := hit.get_collider()
	var normal := hit.get_normal()
	var impact_speed := -velocity.dot(normal)
	if impact_speed <= 0.0:
		return
	var bounciness = body.get("bounciness")
	var friction = body.get("friction")
	if bounciness == null:
		bounciness = 0.6
	if friction == null:
		friction = 0.8
	var straight := normal * velocity.dot(normal)
	velocity = (velocity - straight) * friction - straight * bounciness
	var is_new := body != _last_bounce_body or _clock - _last_bounce_time > 0.15
	if impact_speed >= min_bounce_speed and is_new:
		_last_bounce_body = body
		_last_bounce_time = _clock
		bounced.emit(body)


func _stretch_along(angle: float, length_scale: float, width_scale: float) -> Transform2D:
	var turn := Transform2D(angle, Vector2.ZERO)
	return turn * Transform2D.IDENTITY.scaled(Vector2(length_scale, width_scale)) * turn.affine_inverse()


func _snap_forward() -> void:
	var angle := velocity.angle()
	_tween = create_tween()
	_tween.tween_method(func(t: float) -> void:
		_visual.transform = _stretch_along(angle, 1.0 + 0.4 * t, 1.0 - 0.25 * t)
	, 1.0, 0.0, 0.2)

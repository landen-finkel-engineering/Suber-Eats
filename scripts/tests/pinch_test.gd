extends Node2D
## PINCH TEST: try the Suber-Out launch with your hand.
##
## Pinch your thumb and index finger, pull your hand back, and let go.
## Rico stretches toward your hand while you pull, then launches the opposite way.
## No camera? Hold the left mouse button instead of pinching.
##
## Keys:  R = reset Rico   C = show/hide camera   M = switch hand / mouse
##
## Every number below can be changed in the Inspector (click the PinchTest node).

@export_group("Launch")
## Furthest you can pull back, in game pixels (the screen is 320 x 180).
@export var max_pull := 60.0
## Launch speed for each pixel you pull back.
@export var launch_power := 6.0
## How strongly Rico falls.
@export var gravity := 300.0
## Pulls shorter than this cancel instead of launching.
@export var min_pull_to_launch := 6.0
## Your aim is taken from this many seconds BEFORE you let go, because opening
## your fingers wiggles your hand. 0 = use the exact moment you let go.
@export_range(0.0, 0.3, 0.01) var release_lookback := 0.1

@export_group("Grabbing")
## If on, you have to pinch near Rico to grab him. If off, pinching anywhere grabs him.
@export var must_pinch_near_rico := false
## How near counts as "near Rico", in game pixels.
@export var grab_radius := 30.0
## How long your hand can disappear while pulling before the shot is cancelled.
@export var hand_lost_grace := 0.4
## The part of the camera picture (0-1) that covers the whole game screen.
## Smaller = less arm movement needed.
@export var hand_area := Rect2(0.15, 0.15, 0.7, 0.7)

@export_group("Stretch look")
## How much longer Rico gets at full pull (0.6 = 60% longer).
@export var max_stretch := 0.6
## How much thinner Rico gets at full pull.
@export var max_squash := 0.3
## How far Rico's body slides back toward your hand, as a fraction of the pull.
@export var pull_back_amount := 0.35

@export_group("Bouncing")
## A hit only counts as a bounce if Rico hits at least this hard.
@export var min_bounce_speed := 40.0
## Anything outside this box is "lost in space".
@export var play_area := Rect2(-20, -60, 360, 260)

enum State { READY, HOLDING, FLYING, DONE }

const SCREEN_SIZE := Vector2(320, 180)
const SOURCE_HAND := "HAND"
const SOURCE_MOUSE := "MOUSE"

var state := State.READY
var use_hand := true
var velocity := Vector2.ZERO
var pull := Vector2.ZERO
var anchor := Vector2.ZERO
var hold_source := ""
var bounces := 0
var deliveries := 0
var last_launch_text := "-"

var _rico_start := Vector2.ZERO
var _pull_history: Array[Dictionary] = []  # [{time, pull}]
var _clock := 0.0
var _was_pinching := {SOURCE_HAND: false, SOURCE_MOUSE: false}
var _hand_lost_for := 0.0
var _stuck_for := 0.0
var _last_bounce_body: Object = null
var _last_bounce_time := -1.0
var _pointer := {}

@onready var tracker: HandTracker = $HandTracker
@onready var rico: CharacterBody2D = $Rico
@onready var rico_visual: Node2D = $Rico/Visual
@onready var planet: Area2D = $Planet
@onready var overlay: Node2D = $Overlay
@onready var info_label: Label = %InfoLabel
@onready var status_label: Label = %StatusLabel
@onready var message_label: Label = %MessageLabel
@onready var camera_preview: TextureRect = %CameraPreview
@onready var hand_drawing: Control = %HandDrawing


func _ready() -> void:
	_rico_start = rico.position
	planet.body_entered.connect(_on_planet_body_entered)
	overlay.draw.connect(_draw_overlay)
	hand_drawing.draw.connect(_draw_hand_on_preview)
	message_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_R:
				_reset_rico()
			KEY_C:
				camera_preview.visible = not camera_preview.visible
			KEY_M:
				use_hand = not use_hand
				_show_message("Using " + ("HAND" if use_hand else "MOUSE"))


func _physics_process(delta: float) -> void:
	_clock += delta
	_pointer = _read_pointer()
	match state:
		State.READY:
			_update_ready()
		State.HOLDING:
			_update_holding(delta)
		State.FLYING:
			_update_flying(delta)
	_was_pinching[_pointer.source] = _pointer.pinching
	_update_ui()
	overlay.queue_redraw()
	hand_drawing.queue_redraw()


# ---------------------------------------------------------------------------
# Input: hand if we can see one, otherwise the mouse
# ---------------------------------------------------------------------------

func _read_pointer() -> Dictionary:
	if use_hand and tracker.hand_visible:
		var p := (tracker.hand_position - hand_area.position) / hand_area.size
		p = p.clamp(Vector2.ZERO, Vector2.ONE)
		return {"source": SOURCE_HAND, "pos": p * SCREEN_SIZE, "pinching": tracker.is_pinching}
	return {
		"source": SOURCE_MOUSE,
		"pos": get_global_mouse_position(),
		"pinching": Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),
	}


# ---------------------------------------------------------------------------
# States
# ---------------------------------------------------------------------------

func _update_ready() -> void:
	var just_pinched: bool = _pointer.pinching and not _was_pinching[_pointer.source]
	if not just_pinched:
		return
	if must_pinch_near_rico and _pointer.pos.distance_to(_rico_start) > grab_radius:
		return
	state = State.HOLDING
	hold_source = _pointer.source
	anchor = _pointer.pos
	pull = Vector2.ZERO
	_pull_history.clear()
	_hand_lost_for = 0.0


func _update_holding(delta: float) -> void:
	# Hand vanished mid-pull? Give it a moment before cancelling.
	if hold_source == SOURCE_HAND and not tracker.hand_visible:
		_hand_lost_for += delta
		if _hand_lost_for > hand_lost_grace:
			_cancel_hold("Lost your hand - try again")
		return
	_hand_lost_for = 0.0
	if _pointer.source != hold_source:
		return

	if _pointer.pinching:
		pull = (_pointer.pos - anchor).limit_length(max_pull)
		_pull_history.append({"time": _clock, "pull": pull})
		while _pull_history.size() > 2 and _pull_history[0].time < _clock - 0.5:
			_pull_history.pop_front()
		_pose_stretched_rico()
	else:
		_release()


func _release() -> void:
	var aim := _pull_at(_clock - release_lookback)
	if aim.length() < min_pull_to_launch:
		_cancel_hold("")
		return
	velocity = -aim * launch_power
	state = State.FLYING
	bounces = 0
	_stuck_for = 0.0
	_last_bounce_body = null
	last_launch_text = "%d px pull, %d deg, speed %d" % [
		roundi(aim.length()), roundi(rad_to_deg(-velocity.angle())), roundi(velocity.length())]
	_snap_forward()


func _cancel_hold(message: String) -> void:
	state = State.READY
	pull = Vector2.ZERO
	rico.position = _rico_start
	rico_visual.transform = Transform2D.IDENTITY
	if message != "":
		_show_message(message)


## Your aim from a moment ago (see release_lookback).
func _pull_at(time: float) -> Vector2:
	if _pull_history.is_empty():
		return pull
	var chosen: Vector2 = _pull_history[0].pull
	for entry in _pull_history:
		if entry.time <= time:
			chosen = entry.pull
	return chosen


func _update_flying(delta: float) -> void:
	velocity.y += gravity * delta
	var hit := rico.move_and_collide(velocity * delta)
	if hit:
		_bounce(hit)
	rico_visual.rotation += velocity.x * delta * 0.03

	if not play_area.has_point(rico.position):
		_end_attempt("Lost in space!")
		return
	if velocity.length() < 10.0:
		_stuck_for += delta
		if _stuck_for > 1.0:
			_end_attempt("Rico got stuck!")
	else:
		_stuck_for = 0.0


func _bounce(hit: KinematicCollision2D) -> void:
	var body := hit.get_collider()
	var normal := hit.get_normal()
	var impact_speed := -velocity.dot(normal)
	if impact_speed <= 0.0:
		return
	var bounciness: float = body.get_meta("bounciness", 0.7)
	var friction: float = body.get_meta("friction", 0.9)
	var straight := normal * velocity.dot(normal)
	var along := velocity - straight
	velocity = along * friction - straight * bounciness
	var is_new := body != _last_bounce_body or _clock - _last_bounce_time > 0.15
	if impact_speed >= min_bounce_speed and is_new:
		bounces += 1
		_last_bounce_body = body
		_last_bounce_time = _clock


func _on_planet_body_entered(body: Node) -> void:
	if body == rico and state == State.FLYING:
		deliveries += 1
		_end_attempt("Delivered!  (%d bounce%s)" % [bounces, "" if bounces == 1 else "s"])


func _end_attempt(message: String) -> void:
	state = State.DONE
	_show_message(message)
	await get_tree().create_timer(1.2).timeout
	if state == State.DONE:
		_reset_rico()


func _reset_rico() -> void:
	state = State.READY
	velocity = Vector2.ZERO
	pull = Vector2.ZERO
	rico.position = _rico_start
	rico_visual.transform = Transform2D.IDENTITY


# ---------------------------------------------------------------------------
# Rico's stretch
# ---------------------------------------------------------------------------

func _pose_stretched_rico() -> void:
	var amount := pull.length() / max_pull
	rico.position = _rico_start + pull * pull_back_amount
	if pull.length() < 0.5:
		rico_visual.transform = Transform2D.IDENTITY
		return
	rico_visual.transform = _stretch_along(pull.angle(), 1.0 + max_stretch * amount, 1.0 - max_squash * amount)


## Stretches along a direction without rotating Rico's face.
func _stretch_along(angle: float, length_scale: float, width_scale: float) -> Transform2D:
	var turn := Transform2D(angle, Vector2.ZERO)
	return turn * Transform2D.IDENTITY.scaled(Vector2(length_scale, width_scale)) * turn.affine_inverse()


func _snap_forward() -> void:
	var angle := velocity.angle()
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		rico_visual.transform = _stretch_along(angle, 1.0 + 0.4 * t, 1.0 - 0.25 * t)
	, 1.0, 0.0, 0.2)


# ---------------------------------------------------------------------------
# Drawing and UI
# ---------------------------------------------------------------------------

func _draw_overlay() -> void:
	if _pointer.is_empty():
		return
	var cursor_color := Color(0.4, 0.9, 1.0) if _pointer.source == SOURCE_HAND else Color.WHITE
	if state == State.HOLDING:
		overlay.draw_line(anchor, anchor + pull, Color(1, 1, 1, 0.5), 1.0)
		overlay.draw_circle(anchor, 2.0, Color(1, 1, 1, 0.5))
		# Where Rico will go (ignores bounces).
		var v := -pull * launch_power
		var start := rico.position
		for i in range(1, 12):
			var t := i * 0.06
			var p := start + v * t + Vector2(0, gravity) * 0.5 * t * t
			overlay.draw_circle(p, 1.0, Color(1, 1, 1, 1.0 - i / 12.0))
	if _pointer.pinching:
		overlay.draw_circle(_pointer.pos, 3.0, cursor_color)
	else:
		overlay.draw_arc(_pointer.pos, 4.0, 0, TAU, 16, cursor_color, 1.0)
	if must_pinch_near_rico and state == State.READY:
		overlay.draw_arc(_rico_start, grab_radius, 0, TAU, 32, Color(1, 1, 1, 0.15), 1.0)


func _draw_hand_on_preview() -> void:
	if not camera_preview.visible or not tracker.hand_visible:
		return
	var box := hand_drawing.size
	for point in tracker.landmarks:
		hand_drawing.draw_circle(point * box, 1.0, Color(0.4, 1.0, 0.4))
	var thumb: Vector2 = tracker.landmarks[HandTracker.THUMB_TIP] * box
	var index: Vector2 = tracker.landmarks[HandTracker.INDEX_TIP] * box
	var pinch_color := Color(1, 0.9, 0.2) if tracker.is_pinching else Color(1, 0.3, 0.3)
	hand_drawing.draw_line(thumb, index, pinch_color, 1.0)
	# The box that maps to the game screen.
	hand_drawing.draw_rect(Rect2(hand_area.position * box, hand_area.size * box), Color(1, 1, 1, 0.3), false, 1.0)


func _update_ui() -> void:
	var texture := tracker.get_camera_texture()
	if camera_preview.texture != texture:
		camera_preview.texture = texture
	var input_text := "%s%s" % [_pointer.source, "" if use_hand else " (forced)"]
	var pinch_text := "--"
	if tracker.hand_visible:
		pinch_text = "%.2f  %s" % [tracker.pinch_ratio, "PINCHED" if tracker.is_pinching else "open"]
	info_label.text = "\n".join([
		"INPUT  %s" % input_text,
		"PINCH  %s" % pinch_text,
		"RICO   %s" % State.keys()[state],
		"PULL   %d px" % roundi(pull.length()),
		"LAST   %s" % last_launch_text,
		"BOUNCES %d   DELIVERED %d" % [bounces, deliveries],
	])
	status_label.text = tracker.status


func _show_message(text: String) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.4)

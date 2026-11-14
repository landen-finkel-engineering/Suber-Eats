extends CharacterBody2D

signal launched
signal bounced(body)
signal delivered
signal lost(reason)

enum { READY, HOLDING, FLYING, DONE }

@export var max_pull := 60.0
@export var power := 6.0
@export var gravity := 300.0
@export var lookback := 0.1
@export var max_speed := 700.0

var state = READY
var start_pos: Vector2
var radius := 10.0
var pull := Vector2.ZERO
var anchor := Vector2.ZERO
var history = []
var clock := 0.0
var was_pinching := false
var stuck_time := 0.0
var air_time := 0.0
var blink_in := 3.0
var last_hit
var last_hit_time := -1.0
var tween: Tween

@onready var sprite = $AnimatedSprite2D
@onready var pad = $LaunchPad


func _ready():
	start_pos = position
	radius = $CollisionShape2D.shape.radius
	pad.top_level = true
	pad.global_position = global_position
	was_pinching = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	sprite.animation_finished.connect(sprite.play.bind("default"))


func _process(delta):
	blink_in -= delta
	if blink_in < 0:
		blink_in = randf_range(2, 4)
		if state != FLYING:
			sprite.play("blink")


func flying():
	return state == FLYING


func reset(pos):
	if tween:
		tween.kill()
	start_pos = pos
	position = pos
	state = READY
	velocity = Vector2.ZERO
	pull = Vector2.ZERO
	scale = Vector2.ONE
	sprite.transform = Transform2D.IDENTITY
	sprite.show()
	pad.global_position = pos


func _physics_process(delta):
	clock += delta
	var pos = get_global_mouse_position()
	var pinching = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if state == READY and pinching and not was_pinching:
		state = HOLDING
		anchor = pos
		history.clear()
	elif state == HOLDING and pinching:
		pull = (pos - anchor).limit_length(max_pull)
		history.append([clock, pull])
		if history.size() > 60:
			history.pop_front()
		position = start_pos + pull * 0.35
		stretch(pull.angle(), pull.length() / max_pull)
	elif state == HOLDING:
		let_go()
	elif state == FLYING:
		fly(delta)

	was_pinching = pinching


func let_go():
	var aim = pull
	for h in history:
		if h[0] <= clock - lookback:
			aim = h[1]
	if aim.length() < 6:
		aim = pull
	if aim.length() < 6:
		reset(start_pos)
	else:
		launch(-aim * power)


func launch(v):
	velocity = v
	state = FLYING
	stuck_time = 0
	air_time = 0
	last_hit = null
	launched.emit()
	create_tween().tween_method(func(a): stretch(v.angle(), a), 0.6, 0.0, 0.2)


func stretch(angle, amount):
	var turn = Transform2D(angle, Vector2.ZERO)
	sprite.transform = turn * Transform2D.IDENTITY.scaled(Vector2(1 + 0.6 * amount, 1 - 0.3 * amount)) * turn.affine_inverse()


func fly(delta):
	velocity.y += gravity * delta
	var hit = move_and_collide(velocity * delta)
	if hit:
		bounce_off(hit)
	air_time += delta
	stuck_time = stuck_time + delta if velocity.length() < 10 else 0.0
	if air_time > 15:
		fail("Took too long!")
	elif stuck_time > 1:
		fail("Rico got stuck!")


func bounce_off(hit):
	var body = hit.get_collider()
	var n = hit.get_normal()
	if body.is_in_group("ufos") and n.y > -0.5:
		capture(body, "Captured by a UFO!")
		return
	var speed_in = -velocity.dot(n)
	if speed_in <= 0:
		return
	var straight = n * velocity.dot(n)
	velocity = ((velocity - straight) * body.friction - straight * body.bounce).limit_length(max_speed)
	if speed_in > 40 and (body != last_hit or clock - last_hit_time > 0.15):
		last_hit = body
		last_hit_time = clock
		bounced.emit(body)


func fail(reason):
	if state == FLYING:
		state = DONE
		sprite.hide()
		lost.emit(reason)


func capture(by, reason):
	if state == FLYING:
		vanish_into(by, lost.emit.bind(reason))


func deliver(goal):
	if state == FLYING:
		vanish_into(goal, delivered.emit)


func vanish_into(target, then):
	state = DONE
	tween = create_tween().set_parallel()
	tween.tween_property(self, "global_position", target.global_position, 0.5)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.5)
	tween.tween_property(sprite, "rotation", TAU, 0.5)
	tween.chain().tween_callback(then)

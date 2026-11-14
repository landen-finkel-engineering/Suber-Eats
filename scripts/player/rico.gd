extends CharacterBody2D

# Pinch (the Hand autoload turns that into a mouse press), pull back, let go.
# Rico stretches toward your hand, then flies the other way.

signal launched
signal bounced(body)
signal delivered
signal lost(reason)

enum { READY, HOLDING, FLYING, DONE }

@export var max_pull := 60.0
@export var power := 6.0
@export var gravity := 300.0
# use your aim from a bit before you let go, opening your fingers moves your hand
@export var lookback := 0.1

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
var last_hit
var last_hit_time := -1.0

@onready var sprite = $AnimatedSprite2D
@onready var pad = $LaunchPad


func _ready():
	start_pos = position
	radius = $CollisionShape2D.shape.radius
	# the launch pad stays where Rico started when he moves
	pad.top_level = true
	pad.global_position = global_position
	# a pinch still held from pressing a button shouldn't grab Rico
	was_pinching = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	sprite.animation_finished.connect(func(): sprite.play("default"))
	blink()


func blink():
	while true:
		await get_tree().create_timer(randf_range(2.0, 4.0)).timeout
		if state != FLYING:
			sprite.play("blink")


func flying():
	return state == FLYING


func reset(pos):
	start_pos = pos
	position = pos
	state = READY
	velocity = Vector2.ZERO
	pull = Vector2.ZERO
	scale = Vector2.ONE
	sprite.transform = Transform2D.IDENTITY
	sprite.show()
	pad.global_position = global_position


func _physics_process(delta):
	clock += delta
	var pos = get_global_mouse_position()
	var pinching = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if state == READY and pinching and not was_pinching:
		state = HOLDING
		anchor = pos
		history.clear()
	elif state == HOLDING:
		if pinching:
			pull = (pos - anchor).limit_length(max_pull)
			history.append([clock, pull])
			if history.size() > 60:
				history.pop_front()
			position = start_pos + pull * 0.35
			stretch(pull.angle(), pull.length() / max_pull)
		else:
			let_go()
	elif state == FLYING:
		fly(delta)

	was_pinching = pinching


func let_go():
	var aim = pull
	for h in history:
		if h[0] <= clock - lookback:
			aim = h[1]
	# a really quick flick has no older aim to use
	if aim.length() < 6:
		aim = pull
	if aim.length() < 6:
		reset(start_pos)
		return
	launch(-aim * power)


func launch(v):
	velocity = v
	state = FLYING
	stuck_time = 0
	air_time = 0
	last_hit = null
	launched.emit()
	var tween = create_tween()
	tween.tween_method(func(a): stretch(v.angle(), a), 0.6, 0.0, 0.2)


# stretch the sprite along a direction without turning Rico's face
func stretch(angle, amount):
	var turn = Transform2D(angle, Vector2.ZERO)
	var squash = Transform2D.IDENTITY.scaled(Vector2(1 + 0.6 * amount, 1 - 0.3 * amount))
	sprite.transform = turn * squash * turn.affine_inverse()


func fly(delta):
	velocity.y += gravity * delta
	var hit = move_and_collide(velocity * delta)
	if hit:
		bounce_off(hit)
	air_time += delta
	if air_time > 15:
		fail("Took too long!")
	if velocity.length() < 10:
		stuck_time += delta
		if stuck_time > 1:
			fail("Rico got stuck!")
	else:
		stuck_time = 0


func bounce_off(hit):
	var body = hit.get_collider()
	var n = hit.get_normal()
	var speed_in = -velocity.dot(n)
	if speed_in <= 0:
		return
	var straight = n * velocity.dot(n)
	velocity = (velocity - straight) * body.get("friction") - straight * body.get("bounce")
	# rolling along something shouldn't count as lots of bounces
	if speed_in > 40 and (body != last_hit or clock - last_hit_time > 0.15):
		last_hit = body
		last_hit_time = clock
		bounced.emit(body)


func fail(reason):
	if state == FLYING:
		state = DONE
		sprite.hide()
		lost.emit(reason)


func capture(ufo):
	if state != FLYING:
		return
	state = DONE
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "global_position", ufo.global_position, 0.5)
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.5)
	tween.chain().tween_callback(func(): lost.emit("Captured by a UFO!"))


func deliver(goal):
	if state != FLYING:
		return
	state = DONE
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "global_position", goal.global_position, 0.35)
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.35)
	tween.chain().tween_callback(func(): delivered.emit())

extends Node2D

@export var level_name := "Level 1"
@export var rules: LevelRules
@export var play_area := Rect2(-60, -220, 760, 620)

var time := 0.0
var timer_on := false
var hits := 0
var ufos_beaten = []
var start_pos: Vector2

@onready var rico = $Rico
@onready var hud = $HUD
@onready var camera = $Camera2D
@onready var objects = get_tree().get_nodes_in_group("bouncers")
@onready var ufos = get_tree().get_nodes_in_group("ufos")
@onready var black_holes = get_tree().get_nodes_in_group("black_holes")


func _ready():
	start_pos = rico.position
	rico.launched.connect(_on_rico_launched)
	rico.bounced.connect(_on_rico_bounced)
	rico.lost.connect(_on_rico_lost)
	rico.delivered.connect(_on_rico_delivered)
	$Goal.body_entered.connect(_on_goal_body_entered)
	hud.level = self
	Sound.music(false)
	Sound.play("order")


func _physics_process(delta):
	if not rico.flying():
		return
	if timer_on:
		time += delta
	for thing in black_holes + ufos:
		thing.affect(rico, delta)
	for hole in black_holes:
		if hole.swallows(rico):
			Sound.death(true)
			shake(4)
			rico.spaghettify(hole)
			return
	if not play_area.has_point(rico.global_position):
		rico.fail("Lost in space!")


func _on_rico_launched():
	timer_on = true
	Sound.play("grunt")


func _on_rico_bounced(body):
	if body.is_in_group("ufos"):
		ufos_beaten.append(body)
		body.destroy()
		Sound.play("poof")
		shake(5)
		hitstop()
	elif body.is_in_group("bouncers"):
		hits += 1
		body.hit()
		if body.kick:
			shake(2)


func _on_goal_body_entered(body):
	if body == rico and rico.flying():
		Sound.play("doorbell")
		var tween = create_tween()
		$Goal.scale = Vector2(1.3, 0.8)
		tween.tween_property($Goal, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		rico.deliver($Goal/House)


func _on_rico_lost(reason):
	timer_on = false
	hud.show_message(reason)
	if reason != "Spaghettified!":
		Sound.death(false)
		shake(3)
	await get_tree().create_timer(0.9).timeout
	restart_attempt()


func restart_attempt():
	hits = 0
	ufos_beaten.clear()
	for ufo in ufos:
		ufo.reset()
	rico.reset(start_pos)


func _on_rico_delivered():
	timer_on = false
	Sound.play("win")
	var stars = [time <= rules.time_limit, hits_ok(), ufos_ok()]
	Progress.finish(number(), stars.count(true))
	hud.show_results(stars)


func shake(amount):
	create_tween().tween_method(func(a): camera.offset = Vector2(randf_range(-a, a), randf_range(-a, a)), float(amount), 0.0, 0.25)


func hitstop():
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.07, true, false, true).timeout
	Engine.time_scale = 1.0


func hits_ok():
	return hits >= rules.min_hits and (rules.max_hits == 0 or hits <= rules.max_hits)


func ufos_needed():
	return ufos.size() if rules.ufos_to_beat < 0 else rules.ufos_to_beat


func ufos_ok():
	return ufos_beaten.size() >= ufos_needed()


func number():
	return scene_file_path.get_file().to_int()


func next_level():
	var path = "res://scenes/levels/level_%02d.tscn" % (number() + 1)
	return path if ResourceLoader.exists(path) else ""

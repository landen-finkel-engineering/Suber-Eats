extends Node2D

# Goes on the root of every level.
# Stars: deliver within target_time, use max_objects or fewer, beat every UFO.

@export var level_name := "Level 1"
@export var target_time := 5.0
@export var max_objects := 2
# leave this box and Rico is lost in space
@export var play_area := Rect2(-20, -60, 360, 260)

var time := 0.0
var timer_on := false
var objects_used := 0
var ufos_beaten := 0
var start_pos: Vector2
var ufos = []
var black_holes = []

@onready var rico = $Rico
@onready var hud = $HUD


func _ready():
	start_pos = rico.position
	ufos = get_tree().get_nodes_in_group("ufos")
	black_holes = get_tree().get_nodes_in_group("black_holes")

	rico.launched.connect(_on_rico_launched)
	rico.bounced.connect(_on_rico_bounced)
	rico.lost.connect(_on_rico_lost)
	rico.delivered.connect(_on_rico_delivered)
	$Goal.body_entered.connect(_on_goal_body_entered)
	for ufo in ufos:
		ufo.defeated.connect(_on_ufo_defeated)
	hud.level = self
	Sound.music(false)
	Sound.play("order")


func _physics_process(delta):
	if not rico.flying():
		return
	if timer_on:
		time += delta
	for hole in black_holes:
		rico.velocity += hole.pull(rico.global_position, delta)
		if hole.swallows(rico.global_position, rico.radius):
			rico.fail("Sucked into a black hole!")
			return
	if not play_area.has_point(rico.global_position):
		rico.fail("Lost in space!")


func _on_rico_launched():
	timer_on = true
	Sound.play("grunt")


func _on_ufo_defeated():
	ufos_beaten += 1
	Sound.play("poof")


func _on_rico_bounced(body):
	if body.is_in_group("bouncers"):
		objects_used += 1


func _on_goal_body_entered(body):
	if body == rico and rico.flying():
		Sound.play("doorbell")
		rico.deliver($Goal)


# the timer just pauses, everything else goes back to the start
func _on_rico_lost(reason):
	timer_on = false
	hud.show_message(reason)
	Sound.death(reason.contains("black hole"))
	await get_tree().create_timer(0.9).timeout
	restart_attempt()


func restart_attempt():
	objects_used = 0
	ufos_beaten = 0
	for ufo in ufos:
		ufo.reset()
	rico.reset(start_pos)


func _on_rico_delivered():
	timer_on = false
	Sound.play("win")
	hud.show_results(time <= target_time, objects_used <= max_objects, ufos_beaten >= ufos.size())


# level_03.tscn -> level_04.tscn
func next_level():
	var num = scene_file_path.get_file().to_int() + 1
	var path = "res://scenes/levels/level_%02d.tscn" % num
	if ResourceLoader.exists(path):
		return path
	return ""

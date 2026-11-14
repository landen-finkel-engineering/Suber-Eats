@tool
class_name Level
extends Node2D
## Put this on the root node of every level. It runs the Suber-Out rules:
##   - Rico launches from the StartPoint; the timer only runs while he's flying
##   - every bounce off a LevelObject counts as an object used
##   - UFO beam, black hole, flying off the play area or getting stuck reset the
##     attempt (Rico, UFOs and counts reset; the timer just pauses)
##   - reaching the DeliveryPlanet finishes the level and gives up to 3 stars
## Paint the level with the Level Painter panel (see docs/level_painter.md).

@export var level_name := "Level"
@export_group("3-star goals")
## Star 1: deliver within this many seconds of flying time.
@export var target_time := 5.0
## Star 2: use this many objects or fewer. (Star 3 is always: defeat every UFO.)
@export var max_objects := 2
@export_group("Look")
## Optional background picture (320 x 180).
@export var background: Texture2D:
	set(value):
		background = value
		queue_redraw()
@export var background_color := Color(0.05, 0.04, 0.12):
	set(value):
		background_color = value
		queue_redraw()
@export_group("Play area")
## If Rico leaves this box he's lost in space. The red box in the editor.
@export var play_area := Rect2(-20, -60, 360, 260):
	set(value):
		play_area = value
		queue_redraw()

const SCREEN := Vector2(320, 180)

var rico: Rico
var tracker: HandTracker
var start: StartPoint
var planet: DeliveryPlanet
var ufos: Array[Node] = []
var black_holes: Array[Node] = []
var hud: LevelHud

var elapsed := 0.0
var timer_running := false
var objects_used := 0
var ufos_defeated := 0
var finished := false


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	start = _find("level_start")
	planet = _find("level_planet")
	ufos = _find_all("level_ufos")
	black_holes = _find_all("level_black_holes")
	if start == null or planet == null:
		push_error("This level needs a Start and a Planet. Add them with the Level Painter.")
		return

	tracker = HandTracker.new()
	tracker.name = "HandTracker"
	add_child(tracker)

	rico = Rico.new()
	rico.name = "Rico"
	rico.tracker = tracker
	add_child(rico)
	rico.reset_to(start.global_position)
	rico.launched.connect(_on_launched)
	rico.bounced.connect(_on_bounced)
	rico.lost.connect(_on_lost)
	rico.delivered.connect(_on_delivered)
	planet.body_entered.connect(_on_planet_body_entered)
	for ufo in ufos:
		ufo.defeated.connect(_on_ufo_defeated)

	hud = LevelHud.new()
	hud.level = self
	add_child(hud)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or rico == null:
		return
	if not rico.is_flying():
		return
	if timer_running:
		elapsed += delta
	for hole in black_holes:
		rico.velocity += hole.pull_on(rico.global_position, delta)
		if hole.is_swallowing(rico.global_position, rico.radius):
			rico.fail("Sucked into a black hole!")
			return
	if not play_area.has_point(rico.global_position):
		rico.fail("Lost in space!")


func _on_launched() -> void:
	timer_running = true


func _on_bounced(body: Node) -> void:
	if body is LevelObject:
		objects_used += 1


func _on_ufo_defeated() -> void:
	ufos_defeated += 1


func _on_planet_body_entered(body: Node) -> void:
	if body == rico and rico.is_flying():
		rico.deliver(planet)


func _on_lost(reason: String) -> void:
	timer_running = false
	hud.show_message(reason)
	await get_tree().create_timer(0.9).timeout
	reset_attempt()


## Puts Rico, the UFOs and the counts back. The timer keeps its time.
func reset_attempt() -> void:
	objects_used = 0
	ufos_defeated = 0
	for ufo in ufos:
		ufo.reset()
	rico.reset_to(start.global_position)


func _on_delivered() -> void:
	timer_running = false
	finished = true
	hud.show_results(get_result())


func get_result() -> Dictionary:
	var stars := [
		elapsed <= target_time,
		objects_used <= max_objects,
		ufos_defeated >= ufos.size(),
	]
	return {
		"time": elapsed, "target_time": target_time,
		"objects": objects_used, "max_objects": max_objects,
		"ufos": ufos_defeated, "ufos_total": ufos.size(),
		"stars": stars, "star_count": stars.count(true),
	}


## res://scenes/levels/level_03.tscn -> res://scenes/levels/level_04.tscn (or "" if none).
func get_next_level_path() -> String:
	var regex := RegEx.create_from_string("(\\d+)\\.tscn$")
	var found := regex.search(scene_file_path)
	if found == null:
		return ""
	var number := found.get_string(1)
	var next := str(number.to_int() + 1).pad_zeros(number.length())
	var path := scene_file_path.substr(0, found.get_start(1)) + next + ".tscn"
	return path if ResourceLoader.exists(path) else ""


func _find(group: String) -> Node:
	var all := _find_all(group)
	return all[0] if not all.is_empty() else null


func _find_all(group: String) -> Array[Node]:
	var found: Array[Node] = []
	for node in find_children("*", "", true, false):
		if node.is_in_group(group):
			found.append(node)
	return found


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN), background_color)
	if background != null:
		draw_texture_rect(background, Rect2(Vector2.ZERO, SCREEN), false)
	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 60:
			var p := Vector2(rng.randf() * SCREEN.x, rng.randf() * SCREEN.y)
			draw_rect(Rect2(p.floor(), Vector2.ONE), Color(1, 1, 1, rng.randf_range(0.2, 0.7)))
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(1, 1, 1, 0.4), false, 1.0)
		draw_rect(play_area, Color(1, 0.3, 0.3, 0.35), false, 1.0)

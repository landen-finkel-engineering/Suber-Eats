class_name LevelHud
extends CanvasLayer
## The on-screen info for a level: timer, objects, UFOs, messages, pause menu,
## results with stars, and a small camera preview. Built in code so every level
## gets it automatically. Esc = pause, C = camera preview, M = hand/mouse.

var level: Level

var _stats: Label
var _message: Label
var _hint: Label
var _status: Label
var _preview: TextureRect
var _results: Control
var _results_text: Label
var _next_button: Button
var _pause: Control
var _settings := LabelSettings.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings.font_size = 8
	_settings.outline_size = 2
	_settings.outline_color = Color.BLACK

	_stats = _label(Vector2(4, 2))
	_status = _label(Vector2(4, 168))
	_hint = _label(Vector2(4, 158))
	_hint.text = "Pinch (or hold the mouse), pull back, let go!"

	_preview = TextureRect.new()
	_preview.position = Vector2(256, 4)
	_preview.size = Vector2(60, 45)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_preview)

	_message = Label.new()
	_message.size = Vector2(320, 180)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 16)
	_message.add_theme_constant_override("outline_size", 3)
	_message.add_theme_color_override("font_outline_color", Color.BLACK)
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_message)

	_results = _panel()
	_results_text = _results.get_node("Bg/Box/Text")
	_next_button = _button(_results, "Next level", _on_next)
	_button(_results, "Try again", _on_restart)

	_pause = _panel()
	_pause.get_node("Bg/Box/Text").text = "PAUSED"
	_button(_pause, "Resume", _toggle_pause)
	_button(_pause, "Restart level", _on_restart)


func _process(_delta: float) -> void:
	if level == null:
		return
	var lines := [
		level.level_name,
		"TIME %.1f / %.1f" % [level.elapsed, level.target_time],
		"OBJECTS %d / %d" % [level.objects_used, level.max_objects],
	]
	if level.ufos.size() > 0:
		lines.append("UFOS %d / %d" % [level.ufos_defeated, level.ufos.size()])
	_stats.text = "\n".join(lines)
	_status.text = level.tracker.status if level.tracker else ""
	if level.rico and level.rico.state != Rico.State.READY:
		_hint.visible = false
	var texture := level.tracker.get_camera_texture() if level.tracker else null
	if _preview.texture != texture:
		_preview.texture = texture


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _results.visible:
		_toggle_pause()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_C:
			_preview.visible = not _preview.visible
		elif event.physical_keycode == KEY_M and level.rico:
			level.rico.use_hand = not level.rico.use_hand
			show_message("Using " + ("HAND" if level.rico.use_hand else "MOUSE"))


func show_message(text: String) -> void:
	_message.text = text
	_message.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.7)
	tween.tween_property(_message, "modulate:a", 0.0, 0.3)


func show_results(result: Dictionary) -> void:
	var marks: Array = result.stars.map(func(got: bool) -> String: return "[*]" if got else "[ ]")
	_results_text.text = "\n".join([
		"DELIVERED!   %d / 3 STARS" % result.star_count,
		"%s Time %.1fs (goal %.1fs)" % [marks[0], result.time, result.target_time],
		"%s Objects %d (goal %d)" % [marks[1], result.objects, result.max_objects],
		"%s UFOs %d / %d" % [marks[2], result.ufos, result.ufos_total],
	])
	_next_button.visible = level.get_next_level_path() != ""
	_results.show()


func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	_pause.visible = get_tree().paused


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_next() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(level.get_next_level_path())


func _label(at: Vector2) -> Label:
	var label := Label.new()
	label.position = at
	label.label_settings = _settings
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _panel() -> Control:
	# CenterContainer > "Bg" PanelContainer > "Box" VBoxContainer > "Text" Label
	var center := CenterContainer.new()
	center.size = Vector2(320, 180)
	center.visible = false
	add_child(center)
	var bg := PanelContainer.new()
	bg.name = "Bg"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.16, 0.95)
	style.border_color = Color(0.45, 0.9, 0.45)
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	bg.add_theme_stylebox_override("panel", style)
	center.add_child(bg)
	var box := VBoxContainer.new()
	box.name = "Box"
	bg.add_child(box)
	var text := Label.new()
	text.name = "Text"
	text.label_settings = _settings
	box.add_child(text)
	return center


func _button(panel: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 8)
	button.pressed.connect(action)
	panel.get_node("Bg/Box").add_child(button)
	return button

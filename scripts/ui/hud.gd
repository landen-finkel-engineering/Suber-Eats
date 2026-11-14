extends CanvasLayer

# Esc = pause, C = camera on/off, M = switch hand / mouse

var level


func _process(_delta):
	if level == null:
		return
	var text = "%s\nTIME %.1f / %.1f\nOBJECTS %d / %d" % [level.level_name, level.time, level.target_time, level.objects_used, level.max_objects]
	if level.ufos.size() > 0:
		text += "\nUFOS %d / %d" % [level.ufos_beaten, level.ufos.size()]
	$Stats.text = text
	$Status.text = level.get_node("HandTracker").status
	$Camera.texture = level.get_node("HandTracker").camera_texture()
	if level.rico.state != level.rico.READY:
		$Hint.hide()


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and not $Results.visible:
		_on_resume_pressed()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_C:
		$Camera.visible = not $Camera.visible
	elif event is InputEventKey and event.pressed and event.keycode == KEY_M:
		level.rico.use_hand = not level.rico.use_hand
		show_message("Hand" if level.rico.use_hand else "Mouse")


func show_message(text):
	$Message.text = text
	$Message.modulate.a = 1
	var tween = create_tween()
	tween.tween_interval(0.7)
	tween.tween_property($Message, "modulate:a", 0.0, 0.3)


func show_results(time_star, objects_star, ufo_star):
	var stars = [time_star, objects_star, ufo_star].count(true)
	var lines = ["DELIVERED!  %d / 3 STARS" % stars]
	lines.append(("[*] " if time_star else "[ ] ") + "Time %.1f (goal %.1f)" % [level.time, level.target_time])
	lines.append(("[*] " if objects_star else "[ ] ") + "Objects %d (goal %d)" % [level.objects_used, level.max_objects])
	lines.append(("[*] " if ufo_star else "[ ] ") + "UFOs %d / %d" % [level.ufos_beaten, level.ufos.size()])
	$Results/Panel/List/Text.text = "\n".join(lines)
	$Results/Panel/List/Next.visible = level.next_level() != ""
	$Results.show()


func _on_resume_pressed():
	get_tree().paused = not get_tree().paused
	$Pause.visible = get_tree().paused


func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_next_pressed():
	get_tree().change_scene_to_file(level.next_level())

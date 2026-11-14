extends CanvasLayer

var level


func _process(_delta):
	if level == null:
		return
	var r = level.rules
	$Stats.text = "%s\nTIME %.1f / %.0f\nOBJECTS %d  HITS %d%s\nUFOS %d / %d" % [
		level.level_name, level.time, r.time_limit, level.objects.size(), level.hits, needed_hits(r),
		level.ufos_beaten.size(), level.ufos_needed()]
	$Status.text = Hand.status
	$Camera.texture = Hand.camera_texture()
	if level.rico.state != level.rico.READY:
		$Hint.hide()


func needed_hits(r):
	if r.min_hits and r.max_hits:
		return " (%d-%d)" % [r.min_hits, r.max_hits]
	if r.min_hits:
		return " (MIN %d)" % r.min_hits
	return " (MAX %d)" % r.max_hits if r.max_hits else ""


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and not $Results.visible:
		_on_resume_pressed()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_C:
		$Camera.visible = not $Camera.visible
	elif event is InputEventKey and event.pressed and event.keycode == KEY_M:
		Hand.enabled = not Hand.enabled
		show_message("Hand on" if Hand.enabled else "Hand off")


func show_message(text):
	$Message.text = text
	$Message.modulate.a = 1
	var tween = create_tween()
	tween.tween_interval(0.7)
	tween.tween_property($Message, "modulate:a", 0.0, 0.3)


func show_results(stars):
	for i in 3:
		$Results/Phone/Stars.get_child(i).modulate = Color.GOLD if stars[i] else Color(1, 1, 1, 0.3)
	$Results/Phone/Map.queue_redraw()
	$Results/Next.visible = level.next_level() != ""
	$Results.show()


func _on_resume_pressed():
	get_tree().paused = not get_tree().paused
	$Pause.visible = get_tree().paused


func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_next_pressed():
	get_tree().change_scene_to_file(level.next_level())


func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/title.tscn")

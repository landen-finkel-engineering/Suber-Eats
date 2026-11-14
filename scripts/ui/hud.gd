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
	if level.rico.state != level.rico.READY and $Hint.modulate.a == 1:
		create_tween().tween_property($Hint, "modulate:a", 0.0, 0.3)


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
	$Message.pivot_offset = $Message.size / 2
	$Message.scale = Vector2(1.4, 1.4)
	var tween = create_tween()
	tween.tween_property($Message, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.6)
	tween.tween_property($Message, "modulate:a", 0.0, 0.3)


func show_results(stars):
	for i in 3:
		$Results/Phone/Stars.get_child(i).modulate = Color.GOLD if stars[i] else Color(1, 1, 1, 0.3)
	$Results/Phone/Map.queue_redraw()
	$Results/Next.visible = level.next_level() != ""
	$Results.show()
	$Results.position.y = 180
	create_tween().tween_property($Results, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_resume_pressed():
	get_tree().paused = not get_tree().paused
	$Pause.visible = get_tree().paused


func _on_restart_pressed():
	Transition.go(level.scene_file_path)


func _on_next_pressed():
	Transition.go(level.next_level())


func _on_menu_pressed():
	Transition.go("res://scenes/ui/title.tscn")

extends Control

# Pinch Start to play. The hand moves the cursor (see the Hand autoload).


func _process(_delta):
	$Status.text = Hand.status
	$Camera.texture = Hand.camera_texture()


func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")

extends Control


func _ready():
	$Rico.set_physics_process(false)
	Sound.music(true)


func _process(_delta):
	$Status.text = Hand.status
	$Camera.texture = Hand.camera_texture()


func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")

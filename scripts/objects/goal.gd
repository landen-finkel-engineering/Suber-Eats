@tool
extends Area2D

@export_range(0, 360) var hue := 0.0:
	set(value):
		hue = value
		if is_node_ready():
			tint()


func _ready():
	tint()


func tint():
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://scripts/objects/hue.gdshader")
	mat.set_shader_parameter("hue", hue)
	$Planet.material = mat
	$House.material = mat

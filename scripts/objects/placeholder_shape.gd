@tool
extends Node2D
## A simple colored shape so things are visible before the real art exists.
##
## To use real art: give the sibling node called "Sprite2D" a texture (drag your PNG
## onto its Texture property). This placeholder then hides itself automatically.

enum Shape { CIRCLE, RECT, ALIEN, PLANET }

@export var shape: Shape = Shape.CIRCLE:
	set(value):
		shape = value
		queue_redraw()
## Size in pixels. Circles use the X value as their width.
@export var size := Vector2(16, 16):
	set(value):
		size = value
		queue_redraw()
@export var color := Color.WHITE:
	set(value):
		color = value
		queue_redraw()


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	visible = not _has_real_art()


func _process(_delta: float) -> void:
	# In the editor, hide as soon as someone adds art.
	visible = not _has_real_art()


func _has_real_art() -> bool:
	var sprite := get_parent().get_node_or_null("Sprite2D") as Sprite2D
	return sprite != null and sprite.texture != null


func _draw() -> void:
	var radius := size.x / 2.0
	match shape:
		Shape.CIRCLE:
			draw_circle(Vector2.ZERO, radius, color)
		Shape.RECT:
			draw_rect(Rect2(-size / 2.0, size), color)
		Shape.ALIEN:
			draw_line(Vector2(0, -radius), Vector2(0, -radius - 3), color, 1.0)
			draw_circle(Vector2(0, -radius - 3), 1.5, color.lightened(0.5))
			draw_circle(Vector2.ZERO, radius, color)
			draw_circle(Vector2(-radius * 0.35, -radius * 0.15), 1.5, Color.BLACK)
			draw_circle(Vector2(radius * 0.35, -radius * 0.15), 1.5, Color.BLACK)
		Shape.PLANET:
			draw_circle(Vector2.ZERO, radius, color)
			draw_circle(Vector2(-radius * 0.3, -radius * 0.25), radius * 0.25, color.lightened(0.25))
			var ring := PackedVector2Array()
			for i in 33:
				var a := TAU * i / 32.0
				ring.append(Vector2(cos(a) * radius * 1.5, sin(a) * radius * 0.35))
			draw_polyline(ring, color.lightened(0.4), 1.0)

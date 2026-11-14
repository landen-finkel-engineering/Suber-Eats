@tool
class_name StartPoint
extends Node2D
## Where Rico sits before launch. One per level. The ghost Rico only shows in the editor.

## Optional picture for the launch pad, drawn just under Rico.
@export var pad_texture: Texture2D:
	set(value):
		pad_texture = value
		queue_redraw()
## How far below Rico's center the pad sits.
@export var pad_offset := 14.0:
	set(value):
		pad_offset = value
		queue_redraw()


func _ready() -> void:
	add_to_group("level_start")


func _draw() -> void:
	if pad_texture != null:
		draw_texture(pad_texture, Vector2(-pad_texture.get_width() / 2.0, pad_offset))
	else:
		draw_rect(Rect2(-12, pad_offset, 24, 4), Color(0.55, 0.6, 0.7))
	if Engine.is_editor_hint():
		draw_arc(Vector2.ZERO, 10.0, 0, TAU, 24, Color(0.45, 0.9, 0.45, 0.8), 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(-12, -14), "START", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.45, 0.9, 0.45))

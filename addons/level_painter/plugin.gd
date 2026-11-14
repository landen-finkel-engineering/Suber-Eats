@tool
extends EditorPlugin
## LEVEL PAINTER
## A panel (top right, "Level Painter" tab) for building Suber-Out levels:
##   1. open a level scene (scenes/levels/level_XX.tscn)
##   2. turn on Paint mode
##   3. pick WHAT it is (Solid, Bounce, Slide, Black hole, UFO, Planet, Start)
##   4. pick a PICTURE (any PNG in assets/graphics/, or the placeholder)
##   5. click in the 2D view to place it, right-click an object to erase it
## Ctrl+Z / Cmd+Z undoes. Turn Paint mode off to select, move, rotate and edit objects.

const KINDS := ["Solid", "Bounce", "Slide", "Black hole", "UFO", "Planet", "Start"]
const PICTURE_FOLDER := "res://assets/graphics"

var dock: VBoxContainer
var paint_toggle: CheckButton
var kind_picker: OptionButton
var picture_list: ItemList
var grid_spin: SpinBox
var status_label: Label
var picture_paths: Array[String] = []
var mouse_canvas_pos := Vector2.ZERO


func _enter_tree() -> void:
	_build_dock()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	scene_changed.connect(_on_scene_changed)
	_refresh_pictures()
	_update_status()


func _exit_tree() -> void:
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()


# ---------------------------------------------------------------------------
# Panel
# ---------------------------------------------------------------------------

func _build_dock() -> void:
	dock = VBoxContainer.new()
	dock.name = "Level Painter"

	paint_toggle = CheckButton.new()
	paint_toggle.text = "Paint mode"
	paint_toggle.tooltip_text = "On: click places, right-click erases.\nOff: normal selecting and moving."
	paint_toggle.toggled.connect(_on_paint_toggled)
	dock.add_child(paint_toggle)

	dock.add_child(_heading("1. What is it?"))
	kind_picker = OptionButton.new()
	for kind in KINDS:
		kind_picker.add_item(kind)
	kind_picker.item_selected.connect(func(_i: int) -> void: update_overlays())
	dock.add_child(kind_picker)

	dock.add_child(_heading("2. Picture"))
	picture_list = ItemList.new()
	picture_list.fixed_icon_size = Vector2i(32, 32)
	picture_list.icon_mode = ItemList.ICON_MODE_LEFT
	picture_list.custom_minimum_size = Vector2(0, 220)
	picture_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	picture_list.item_selected.connect(func(_i: int) -> void: update_overlays())
	dock.add_child(picture_list)
	var refresh := Button.new()
	refresh.text = "Refresh pictures"
	refresh.pressed.connect(_refresh_pictures)
	dock.add_child(refresh)

	var grid_row := HBoxContainer.new()
	var grid_label := Label.new()
	grid_label.text = "Grid snap (px)"
	grid_row.add_child(grid_label)
	grid_spin = SpinBox.new()
	grid_spin.min_value = 0
	grid_spin.max_value = 64
	grid_spin.value = 8
	grid_spin.tooltip_text = "0 = no snapping"
	grid_row.add_child(grid_spin)
	dock.add_child(grid_row)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock.add_child(status_label)

	var help := Label.new()
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.modulate = Color(1, 1, 1, 0.6)
	help.text = "Click = place.  Right-click = erase.  Ctrl/Cmd+Z = undo.\nStart and Planet move instead of copying (one each per level).\nPaint mode off = select an object to move it or change its settings in the Inspector.\nPictures: put PNGs anywhere in assets/graphics/, then Refresh."
	dock.add_child(help)


func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	return label


func _refresh_pictures() -> void:
	picture_paths.clear()
	_collect_pngs(PICTURE_FOLDER)
	picture_paths.sort()
	var keep := _selected_picture_path()
	picture_list.clear()
	picture_list.add_item("(placeholder)")
	for path in picture_paths:
		var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
		picture_list.add_item(path.trim_prefix(PICTURE_FOLDER + "/"), texture)
	var index := picture_paths.find(keep)
	picture_list.select(index + 1 if index >= 0 else 0)


func _collect_pngs(folder: String) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		return
	for file in dir.get_files():
		if file.get_extension().to_lower() == "png":
			picture_paths.append(folder.path_join(file))
	for sub in dir.get_directories():
		_collect_pngs(folder.path_join(sub))


func _selected_picture_path() -> String:
	if picture_list == null:
		return ""
	var selected := picture_list.get_selected_items()
	if selected.is_empty() or selected[0] == 0:
		return ""
	return picture_paths[selected[0] - 1]


func _selected_texture() -> Texture2D:
	var path := _selected_picture_path()
	return load(path) if path != "" else null


func _on_paint_toggled(on: bool) -> void:
	if on and _level_root() != null:
		# The painter only receives clicks while something in the level is selected.
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(_level_root())
	_update_status()
	update_overlays()


func _on_scene_changed(_root: Node) -> void:
	_update_status()


func _update_status() -> void:
	if status_label == null:
		return
	if _level_root() == null:
		status_label.text = "Open a level scene (scenes/levels/) to paint."
	elif paint_toggle.button_pressed:
		status_label.text = "PAINTING - click in the 2D view."
	else:
		status_label.text = "Paint mode is off."


# ---------------------------------------------------------------------------
# Clicking in the 2D view
# ---------------------------------------------------------------------------

func _level_root() -> Node:
	var root := EditorInterface.get_edited_scene_root()
	return root if root is Level else null


func _handles(object: Object) -> bool:
	return object is Node and _level_root() != null


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if not paint_toggle.button_pressed or _level_root() == null:
		return false
	var to_canvas := EditorInterface.get_editor_viewport_2d().global_canvas_transform.affine_inverse()
	if event is InputEventMouseMotion:
		mouse_canvas_pos = _snap(to_canvas * (event.position as Vector2))
		update_overlays()
		return false
	if event is InputEventMouseButton and event.pressed:
		var at: Vector2 = to_canvas * event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			place(KINDS[kind_picker.selected], _snap(at), _selected_texture())
			return true
		if event.button_index == MOUSE_BUTTON_RIGHT:
			erase_at(at)
			return true
	return false


func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if not paint_toggle.button_pressed or _level_root() == null:
		return
	var to_screen := EditorInterface.get_editor_viewport_2d().global_canvas_transform
	var zoom := to_screen.get_scale()
	var center: Vector2 = to_screen * mouse_canvas_pos
	var texture := _selected_texture()
	var ghost_size := texture.get_size() if texture else Vector2(16, 16)
	var rect := Rect2(center - ghost_size * zoom / 2.0, ghost_size * zoom)
	if texture:
		overlay.draw_texture_rect(texture, rect, false, Color(1, 1, 1, 0.5))
	overlay.draw_rect(rect, Color(0.4, 0.9, 1.0, 0.8), false, 1.0)
	overlay.draw_string(overlay.get_theme_default_font(), rect.position - Vector2(0, 4),
		KINDS[kind_picker.selected], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.9, 1.0))


func _snap(point: Vector2) -> Vector2:
	var grid := grid_spin.value if grid_spin else 0.0
	return (point / grid).round() * grid if grid > 0.0 else point


## Places an object of the given kind at a canvas position. Undoable.
func place(kind: String, at: Vector2, texture: Texture2D) -> Node:
	var root := _level_root()
	if root == null:
		return null
	var undo := get_undo_redo()

	# Only one Start and one Planet: move the existing one.
	if kind == "Start" or kind == "Planet":
		var existing: Node2D = null
		for node in root.find_children("*", "", true, true):
			if (kind == "Start" and node is StartPoint) or (kind == "Planet" and node is DeliveryPlanet):
				existing = node
				break
		if existing != null:
			undo.create_action("Move " + kind)
			undo.add_do_property(existing, "global_position", at)
			undo.add_undo_property(existing, "global_position", existing.global_position)
			var property := "pad_texture" if kind == "Start" else "texture"
			if texture != null:
				undo.add_do_property(existing, property, texture)
				undo.add_undo_property(existing, property, existing.get(property))
			undo.commit_action()
			return existing

	var node := _make(kind, texture)
	var parent: Node2D = root.get_node_or_null("Objects")
	if parent == null:
		parent = root
	node.position = parent.get_global_transform().affine_inverse() * at
	undo.create_action("Paint " + kind)
	undo.add_do_method(parent, "add_child", node, true)
	undo.add_do_method(node, "set_owner", root)
	undo.add_do_reference(node)
	undo.add_undo_method(parent, "remove_child", node)
	undo.commit_action()
	return node


func _make(kind: String, texture: Texture2D) -> Node2D:
	var node: Node2D
	match kind:
		"Solid", "Bounce", "Slide":
			var object := LevelObject.new()
			object.kind = ["Solid", "Bounce", "Slide"].find(kind)
			object.bounciness = LevelObject.PRESETS[object.kind].bounciness
			object.friction = LevelObject.PRESETS[object.kind].friction
			object.texture = texture
			node = object
		"Black hole":
			var hole := BlackHole.new()
			hole.texture = texture
			node = hole
		"UFO":
			var ufo := UFO.new()
			ufo.texture = texture
			node = ufo
		"Planet":
			var planet := DeliveryPlanet.new()
			planet.texture = texture
			node = planet
		"Start":
			var start := StartPoint.new()
			start.pad_texture = texture
			node = start
	node.name = kind.replace(" ", "")
	return node


## Erases the painted object under a canvas position. Undoable.
func erase_at(at: Vector2) -> bool:
	var root := _level_root()
	if root == null:
		return false
	var nodes := root.find_children("*", "", true, true)
	nodes.reverse()  # topmost first
	for node in nodes:
		if not (node is LevelObject or node is BlackHole or node is UFO):
			continue
		if not _hit(node, at):
			continue
		var parent := node.get_parent()
		var undo := get_undo_redo()
		undo.create_action("Erase " + node.name)
		undo.add_do_method(parent, "remove_child", node)
		undo.add_undo_method(parent, "add_child", node, true)
		undo.add_undo_method(parent, "move_child", node, node.get_index())
		undo.add_undo_method(node, "set_owner", root)
		undo.add_undo_reference(node)
		undo.commit_action()
		return true
	return false


func _hit(node: Node2D, at: Vector2) -> bool:
	var local := node.get_global_transform().affine_inverse() * at
	var box := Vector2(16, 16)
	if node is LevelObject:
		box = node.get_box_size()
	elif node is UFO:
		box = node.get_body_size()
	elif node is BlackHole:
		box = Vector2.ONE * maxf(node.core_radius * 2.0, 12.0)
	return Rect2(-box / 2.0, box).has_point(local)

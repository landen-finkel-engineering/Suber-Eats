@tool
extends EditorPlugin

# Level Painter: open a level, turn on Paint, pick a type and a picture,
# click to place, right-click to erase. Ctrl/Cmd+Z undoes.

const SCENES = {
	"Solid": "res://scenes/objects/bouncer.tscn",
	"Bounce": "res://scenes/objects/bouncer.tscn",
	"Slide": "res://scenes/objects/bouncer.tscn",
	"Black hole": "res://scenes/objects/black_hole.tscn",
	"UFO": "res://scenes/enemies/ufo.tscn",
}
# bounce, friction
const FEEL = {"Solid": [0.6, 0.8], "Bounce": [1.3, 0.95], "Slide": [0.15, 1.0]}
# picture used when "(default)" is picked
const DEFAULT_PICTURES = {"Bounce": "res://assets/graphics/unorganized/trampoline.png"}
const TYPES = ["Solid", "Bounce", "Slide", "Black hole", "UFO", "Goal", "Rico"]

var dock
var paint
var type_list
var picture_list
var pictures = []


func _enter_tree():
	dock = VBoxContainer.new()
	dock.name = "Level Painter"
	paint = CheckButton.new()
	paint.text = "Paint"
	paint.toggled.connect(_on_paint_toggled)
	dock.add_child(paint)
	type_list = OptionButton.new()
	for t in TYPES:
		type_list.add_item(t)
	dock.add_child(type_list)
	picture_list = ItemList.new()
	picture_list.fixed_icon_size = Vector2i(32, 32)
	picture_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dock.add_child(picture_list)
	var refresh = Button.new()
	refresh.text = "Refresh pictures"
	refresh.pressed.connect(load_pictures)
	dock.add_child(refresh)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	load_pictures()


func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()


# every png in assets/graphics
func load_pictures():
	pictures = []
	find_pngs("res://assets/graphics")
	picture_list.clear()
	picture_list.add_item("(default)")
	for path in pictures:
		picture_list.add_item(path.get_file().get_basename(), load(path))
	picture_list.select(0)


func find_pngs(folder):
	var dir = DirAccess.open(folder)
	for file in dir.get_files():
		if file.ends_with(".png"):
			pictures.append(folder + "/" + file)
	for sub in dir.get_directories():
		find_pngs(folder + "/" + sub)


func level():
	var root = EditorInterface.get_edited_scene_root()
	if root and root.scene_file_path.begins_with("res://scenes/levels/"):
		return root
	return null


func _on_paint_toggled(on):
	# clicks only reach the painter while something in the level is selected
	if on and level():
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(level())


func _handles(object):
	return level() != null


func _forward_canvas_gui_input(event):
	if not paint.button_pressed or level() == null:
		return false
	if event is InputEventMouseButton and event.pressed:
		var pos = EditorInterface.get_editor_viewport_2d().global_canvas_transform.affine_inverse() * event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			place(TYPES[type_list.selected], pos.snapped(Vector2(8, 8)), selected_picture())
			return true
		if event.button_index == MOUSE_BUTTON_RIGHT:
			erase(pos)
			return true
	return false


func selected_picture():
	var i = picture_list.get_selected_items()
	if i.is_empty() or i[0] == 0:
		return null
	return load(pictures[i[0] - 1])


func place(type, pos, picture):
	var root = level()
	var undo = get_undo_redo()

	# there's only one Goal and one Rico, so move them
	if type == "Goal" or type == "Rico":
		var node = root.get_node(type)
		undo.create_action("Move " + type)
		undo.add_do_property(node, "position", pos)
		undo.add_undo_property(node, "position", node.position)
		if type == "Goal" and picture:
			undo.add_do_property(node, "texture", picture)
			undo.add_undo_property(node, "texture", node.texture)
		undo.commit_action()
		return

	var node = load(SCENES[type]).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	node.name = type.replace(" ", "")
	node.position = pos
	if picture == null and type in DEFAULT_PICTURES:
		picture = load(DEFAULT_PICTURES[type])
	if picture:
		node.texture = picture
		# planets get a round hit box, everything else a box
		if type in FEEL:
			node.round = picture.resource_path.get_file().begins_with("planet")
	if type in FEEL:
		node.bounce = FEEL[type][0]
		node.friction = FEEL[type][1]
	var parent = root.get_node("Objects")
	undo.create_action("Paint " + type)
	undo.add_do_method(parent, "add_child", node, true)
	undo.add_do_method(node, "set_owner", root)
	undo.add_do_reference(node)
	undo.add_undo_method(parent, "remove_child", node)
	undo.commit_action()


func erase(pos):
	var root = level()
	var objects = root.get_node("Objects").get_children()
	objects.reverse()
	for node in objects:
		var rect = Rect2(-8, -8, 16, 16)
		if node.texture:
			rect = Rect2(-node.texture.get_size() / 2, node.texture.get_size())
		if not rect.has_point(node.to_local(pos)):
			continue
		var undo = get_undo_redo()
		undo.create_action("Erase " + node.name)
		undo.add_do_method(root.get_node("Objects"), "remove_child", node)
		undo.add_undo_method(root.get_node("Objects"), "add_child", node, true)
		undo.add_undo_method(node, "set_owner", root)
		undo.add_undo_reference(node)
		undo.commit_action()
		return

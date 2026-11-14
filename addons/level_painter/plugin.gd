@tool
extends EditorPlugin

const SCENES = {
	"Planet": "res://scenes/objects/bouncer.tscn",
	"Trampoline": "res://scenes/objects/bouncer.tscn",
	"Asteroid belt": "res://scenes/objects/bouncer.tscn",
	"Car": "res://scenes/objects/car.tscn",
	"Black hole": "res://scenes/objects/black_hole.tscn",
	"UFO": "res://scenes/enemies/ufo.tscn",
}
const PICTURES = {
	"Trampoline": "res://assets/graphics/unorganized/trampoline.png",
	"Asteroid belt": "res://assets/graphics/unorganized/asteroid-belt.png",
}
const TYPES = ["Planet", "Trampoline", "Asteroid belt", "Car", "Black hole", "UFO", "Goal", "Rico"]
const RULES = ["time_limit", "min_hits", "max_hits", "ufos_to_beat"]

var dock
var rules_dock
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

	rules_dock = ScrollContainer.new()
	rules_dock.name = "Level Rules"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, rules_dock)
	load_rules()


func _exit_tree():
	remove_control_from_docks(dock)
	remove_control_from_docks(rules_dock)
	dock.free()
	rules_dock.free()


func load_rules():
	for child in rules_dock.get_children():
		child.free()
	var grid = GridContainer.new()
	grid.columns = 5
	rules_dock.add_child(grid)
	for heading in ["Level", "Time (s)", "Min hits", "Max hits\n0 = none", "UFOs\n-1 = all"]:
		var label = Label.new()
		label.text = heading
		grid.add_child(label)
	for file in DirAccess.get_files_at("res://data/levels"):
		if not file.ends_with(".tres"):
			continue
		var rules = load("res://data/levels/" + file)
		var label = Label.new()
		label.text = str(file.to_int())
		grid.add_child(label)
		for key in RULES:
			var box = SpinBox.new()
			box.min_value = -1
			box.max_value = 999
			box.step = 0.5 if key == "time_limit" else 1
			box.value = rules.get(key)
			box.value_changed.connect(func(v):
				rules.set(key, v)
				ResourceSaver.save(rules)
			)
			grid.add_child(box)


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


func _on_paint_toggled(on):
	if on and level():
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(level())


func _handles(object):
	return level() != null


func _forward_canvas_gui_input(event):
	if not paint.button_pressed or level() == null or not event is InputEventMouseButton or not event.pressed:
		return false
	var pos = EditorInterface.get_editor_viewport_2d().global_canvas_transform.affine_inverse() * event.position
	if event.button_index == MOUSE_BUTTON_LEFT:
		place(TYPES[type_list.selected], pos.snapped(Vector2(8, 8)), selected_picture())
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		erase(pos)
	else:
		return false
	return true


func selected_picture():
	var i = picture_list.get_selected_items()
	if i.is_empty() or i[0] == 0:
		return null
	return load(pictures[i[0] - 1])


func place(type, pos, picture):
	var root = level()
	var undo = get_undo_redo()
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
	if type in PICTURES and not picture:
		picture = load(PICTURES[type])
	if picture and "texture" in node:
		node.texture = picture
		node.round = picture.resource_path.get_file().begins_with("planet")
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
		var sprite = node.get_node("Sprite2D")
		if not sprite.get_rect().has_point(sprite.to_local(pos)):
			continue
		var undo = get_undo_redo()
		undo.create_action("Erase " + node.name)
		undo.add_do_method(root.get_node("Objects"), "remove_child", node)
		undo.add_undo_method(root.get_node("Objects"), "add_child", node, true)
		undo.add_undo_method(node, "set_owner", root)
		undo.add_undo_reference(node)
		undo.commit_action()
		return

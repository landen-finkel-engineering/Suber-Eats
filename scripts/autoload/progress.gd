extends Node

const FILE = "user://progress.cfg"

var stars = {}


func _ready():
	var save = ConfigFile.new()
	if save.load(FILE) == OK:
		stars = save.get_value("progress", "stars", {})


func finish(level, got):
	stars[level] = max(stars.get(level, 0), got)
	var save = ConfigFile.new()
	save.set_value("progress", "stars", stars)
	save.save(FILE)


func done(level):
	return stars.has(level)

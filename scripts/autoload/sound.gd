extends Node

# Autoloaded as "Sound". Sound.play("doorbell"), Sound.death(false)

const SFX = "res://assets/audio/sfx/"

var sounds = {
	"order": preload(SFX + "Suber Eat’s Order.ogg"),
	"grunt": preload(SFX + "freesound_community-grunt-1-85280.mp3"),
	"poof": preload(SFX + "freesound_community-poof-80161.mp3"),
	"doorbell": preload(SFX + "u_rbsjsi42wd-doorbell-223669.mp3"),
	"win": preload(SFX + "floraphonic-you-win-sequence-2-183949.mp3"),
	"dying": preload(SFX + "Dying SFX.ogg"),
	"black_hole": preload(SFX + "Dying to Black Hole.ogg"),
}
var ragebait = [
	preload(SFX + "Ragebait lines.ogg"),
	preload(SFX + "Ragebait Lines Burger.ogg"),
]

var players = []
var voice = AudioStreamPlayer.new()
var deaths := 0


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(voice)
	for i in 4:
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)


func play(sound):
	for p in players:
		if not p.playing:
			p.stream = sounds[sound]
			p.play()
			return


func stop_all():
	voice.stop()
	for p in players:
		p.stop()


# dying sound, then a rage bait line
func death(black_hole):
	deaths += 1
	var this_death = deaths
	voice.stream = sounds["black_hole" if black_hole else "dying"]
	voice.play()
	await voice.finished
	if this_death == deaths:
		voice.stream = ragebait.pick_random()
		voice.play()

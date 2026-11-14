extends Node

# Autoloaded as "Sound". Sound.play("doorbell"), Sound.death(false), Sound.music(true)

const SFX = "res://assets/audio/sfx/"

var sounds = {
	"order": preload(SFX + "Suber Eat’s Order.ogg"),
	"grunt": preload(SFX + "Grunt.wav"),
	"poof": preload(SFX + "freesound_community-poof-80161.mp3"),
	"doorbell": preload(SFX + "u_rbsjsi42wd-doorbell-223669.mp3"),
	"win": preload(SFX + "floraphonic-you-win-sequence-2-183949.mp3"),
	"dying": preload(SFX + "Dying SFX.ogg"),
	"black_hole": preload(SFX + "Dying to Black Hole.ogg"),
}
var ragebait = [
	preload(SFX + "Ragebait lines.wav"),
	preload(SFX + "Ragebait Lines Burger.wav"),
]
var menu_music = preload(SFX + "Main Menu.wav")

var players = []
var voice = AudioStreamPlayer.new()
var music_player = AudioStreamPlayer.new()
var deaths := 0


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(voice)
	add_child(music_player)
	music_player.stream = menu_music
	music_player.finished.connect(music_player.play)
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


func music(on):
	if on and not music_player.playing:
		music_player.play()
	elif not on:
		music_player.stop()


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

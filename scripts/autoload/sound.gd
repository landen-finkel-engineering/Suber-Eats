extends Node

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
var ragebait = [preload(SFX + "Ragebait lines.wav"), preload(SFX + "Ragebait Lines Burger.wav")]
var players = []
var voice = AudioStreamPlayer.new()
var music_player = AudioStreamPlayer.new()
var deaths := 0


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(voice)
	add_child(music_player)
	music_player.stream = preload(SFX + "Main Menu.wav")
	music_player.finished.connect(music_player.play)
	for i in 4:
		players.append(AudioStreamPlayer.new())
		add_child(players[i])


func play(sound):
	for p in players:
		if not p.playing:
			p.stream = sounds[sound]
			p.play()
			return


func music(on):
	if not on:
		music_player.stop()
	elif not music_player.playing:
		music_player.play()


func death(black_hole):
	deaths += 1
	var this_death = deaths
	voice.stream = sounds["black_hole" if black_hole else "dying"]
	voice.play()
	await voice.finished
	if this_death == deaths:
		voice.stream = ragebait.pick_random()
		voice.play()

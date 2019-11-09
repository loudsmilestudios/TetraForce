extends Node

var music = AudioStreamPlayer.new()
var music_volume = linear2db(.75)

func _ready():
	pause_mode = PAUSE_MODE_PROCESS

func play(audio):
	get_tree().get_root().add_child(music)
	music.set_stream(audio)
	music.set_volume_db(music_volume)
	music.connect("finished",music,"queue_free")
	music.play()

func change_volume(volume):
	music_volume = linear2db(volume)
	music.set_volume_db(music_volume)

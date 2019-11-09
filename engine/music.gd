extends Node

var music = AudioStreamPlayer.new()

func _ready():
	pause_mode = PAUSE_MODE_PROCESS

func play(audio):
	var volume = linear2db(.25)
	get_tree().get_root().add_child(music)
	music.set_stream(audio)
	music.set_volume_db(volume)
	music.connect("finished",music,"queue_free")
	music.play()

func change_volume(volume):
	music.set_volume_db(linear2db(volume))

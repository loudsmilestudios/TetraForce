extends Node

var sfx_volume = linear2db(.05)

func _ready():
	pause_mode = PAUSE_MODE_PROCESS

func play(sound):
	var sfx = AudioStreamPlayer.new()
	get_tree().get_root().add_child(sfx)
	sfx.set_stream(sound)
	sfx.set_volume_db(sfx_volume)
	sfx.connect("finished",sfx,"queue_free")
	sfx.play()

func change_volume(volume):
	sfx_volume = linear2db(volume)

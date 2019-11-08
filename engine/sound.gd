extends Node

func _ready():
	pause_mode = PAUSE_MODE_PROCESS

func play(sound, volume_modifier=0):
	print("Audio played")
	var volume = linear2db(.05 + volume_modifier)
	var sfx = AudioStreamPlayer.new()
	get_tree().get_root().add_child(sfx)
	sfx.set_stream(sound)
	sfx.set_volume_db(volume)
	sfx.connect("finished",sfx,"queue_free")
	sfx.play()

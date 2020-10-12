extends Node

func play(sound, volume=0):
	var path = str("res://sound/sfx/", sound, ".ogg")
	var new_sound = AudioStreamPlayer.new()
	get_tree().get_root().add_child(new_sound)
	new_sound.set_stream(load(path))
	new_sound.set_volume_db(-15 + volume)
	new_sound.connect("finished", new_sound, "queue_free")
	new_sound.play()

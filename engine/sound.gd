extends Node

var sfx_volume = linear2db(.75)

func _ready():
	pause_mode = PAUSE_MODE_PROCESS

# Volume modifier allows individual sounds to have custom volume, 
# regardless of audio volume settings
func play(sound, volume_modifier=0, modify_increase = true) -> void:
	var play_volume = sfx_volume
	
	if volume_modifier != 0:
		if modify_increase:
			play_volume = -abs(play_volume / linear2db(volume_modifier))
		else:
			play_volume = -abs(play_volume * linear2db(volume_modifier))
	
	var sfx = AudioStreamPlayer.new()
	get_tree().get_root().add_child(sfx)
	sfx.set_stream(sound)
	sfx.set_volume_db(play_volume)
	sfx.connect("finished",sfx,"queue_free")
	sfx.play()

func change_volume(volume):
	sfx_volume = linear2db(volume)

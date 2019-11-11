extends Node

func _ready() -> void:
	pause_mode = PAUSE_MODE_PROCESS

func play(sound, volume=0) -> void:
	var sfx: AudioStreamPlayer = AudioStreamPlayer.new()
	get_tree().get_root().add_child(sfx)
	sfx.set_stream(sound)
	sfx.set_volume_db(-40000 + volume) # FIX THIS LATER
	sfx.connect("finished",sfx,"queue_free")
	sfx.play()

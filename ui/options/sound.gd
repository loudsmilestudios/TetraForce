extends Control

onready var master_slider : Slider = $VBoxContainer/Master/Slider
onready var music_slider : Slider = $VBoxContainer/Music/Slider
onready var sfx_slider : Slider = $VBoxContainer/Sfx/Slider

func _ready():
	global.connect("options_loaded", self, "update_options")
	
	master_slider.value = 50
	music_slider.value = 50
	sfx_slider.value = 50
	on_master_slider_change(master_slider.value)
	on_music_slider_change(music_slider.value)
	on_sfx_slider_change(sfx_slider.value)
	master_slider.connect("value_changed", self, "on_master_slider_change")
	music_slider.connect("value_changed", self, "on_music_slider_change")
	sfx_slider.connect("value_changed", self, "on_sfx_slider_change")

func update_options():
	if not "sound" in global.options:
		global.options["sound"] = {}
	if "master_volume" in global.options.sound:
		master_slider.value = global.options.sound.master_volume
		on_master_slider_change(master_slider.value)
	if "music_volume" in global.options.sound:
		music_slider.value = global.options.sound.music_volume
		on_music_slider_change(music_slider.value)
	if "sfx_volume" in global.options.sound:
		sfx_slider.value = global.options.sound.sfx_volume
		on_sfx_slider_change(sfx_slider.value)

func db_to_percent(db : float) -> float:
	return db2linear(db)

func percent_to_db(pct : float) -> float:
	return linear2db(pct / 100)

func on_master_slider_change(new_value):
	if not "sound" in global.options:
		global.options["sound"] = {}
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), percent_to_db(new_value))
	global.options.sound.master_volume = new_value

func on_music_slider_change(new_value):
	if not "sound" in global.options:
		global.options["sound"] = {}
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), percent_to_db(new_value))
	global.options.sound.music_volume = new_value

func on_sfx_slider_change(new_value):
	if not "sound" in global.options:
		global.options["sound"] = {}
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound Effects"), percent_to_db(new_value))
	global.options.sound.sfx_volume = new_value

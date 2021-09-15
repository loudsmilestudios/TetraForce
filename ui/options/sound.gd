extends Control

onready var master_slider : Slider = $VBoxContainer/Master/Slider

func _ready():
	global.connect("options_loaded", self, "update_options")
	
	master_slider.value = 50
	on_master_slider_change(master_slider.value)
	master_slider.connect("value_changed", self, "on_master_slider_change")

func update_options():
	if not "sound" in global.options:
		global.options["sound"] = {}
	if "master_volume" in global.options.sound:
		master_slider.value = global.options.sound.master_volume
		on_master_slider_change(master_slider.value)

func db_to_percent(db : float) -> float:
	return db2linear(db)

func percent_to_db(pct : float) -> float:
	return linear2db(pct / 100)

func on_master_slider_change(new_value):
	if not "sound" in global.options:
		global.options["sound"] = {}
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), percent_to_db(new_value))
	global.options.sound.master_volume = new_value

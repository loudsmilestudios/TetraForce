extends Control

onready var master_slider : Slider = $VBoxContainer/Master/Slider

func _ready():
	master_slider.value = db_to_percent(0)
	master_slider.connect("value_changed", self, "on_master_slider_change")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 0)

func db_to_percent(db : float) -> float:
	return ((db + 6) / 86) * 100

func percent_to_db(pct : float) -> float:
	return pct / 100 * 86 - 6

func on_master_slider_change(new_value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), percent_to_db(new_value))

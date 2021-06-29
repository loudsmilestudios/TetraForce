extends Control

func _ready():
	global.load_options()

func on_back_button_pressed():
	queue_free()

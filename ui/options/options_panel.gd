extends Control

func _ready():
	global.load_options()
	$back.grab_focus()

func _input(event):
	if Input.is_action_just_pressed("ESC"):
		global.save_options()
		on_back_button_pressed()

func on_back_button_pressed():
	global.save_options()
	queue_free()

extends Control

func _ready():
	global.load_options()
	$back.grab_focus()

func _input(event):
	if Input.is_action_just_pressed("ESC"):
		on_back_button_pressed()

func on_back_button_pressed():
	queue_free()

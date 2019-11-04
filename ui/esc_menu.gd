extends Popup

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _input(event):
	if event is InputEventKey:
		if event.pressed && event.scancode == KEY_ESCAPE:
			self.popup()

func _on_resume_pressed():
	self.hide()

func _on_quit_game_pressed():
	get_tree().quit()

func _on_goto_lobby_pressed():
	# Currently disabled because it does not work properly
	# Needs to properly shut down and restart if running as server
	if get_tree().is_network_server():
		get_tree().set_network_peer(null)
	get_tree().change_scene("res://engine/lobby.tscn")
	self.hide()

func _on_options_pressed():
	pass # Replace with function body.

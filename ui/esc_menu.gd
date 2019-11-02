extends Popup

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("ui_cancel"):
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

extends Control

export(Array, Texture) var Backgrounds = [] # Array of valid background images

func _ready():
	self.hide()
	start_loading("server")

# Displays and configures loading screen
func start_loading(initial_message = "TetraForce"):
	set_loading_message(initial_message)
	update_background_image()
	$animation_player.play("loading")
	$logo.play()
	self.show()

# Hides loading screen and stops animations
func stop_loading():
	$animation_player.stop()
	$logo.stop()
	self.hide()

# Update current loading message
func set_loading_message(message = "Loading"):
	$HBoxContainer/message.text = message

# Randomly select a valid background for the loading screen
func update_background_image():
	$background.texture = Backgrounds[randi() % Backgrounds.size()]

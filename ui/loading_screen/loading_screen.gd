extends Control

var loading : bool = false
export(Array, Texture) var Backgrounds = [] # Array of valid background images

func _ready():
	self.hide()

# Displays and configures loading screen
func start_loading(initial_message = "TetraForce"):
	set_loading_message(initial_message)
	update_background_image()
	$animation_player.play("loading")
	$logo.play()
	self.show()
	loading = true

# Hides loading screen and stops animations
func stop_loading():
	$animation_player.stop()
	$logo.stop()
	loading = false
	self.hide()

# Starts loading if not already
func with_load(message = "TetraForce"):
	if not loading:
		start_loading(message)
	else:
		set_loading_message(message)

# Update current loading message
func set_loading_message(message):
	print("Loading: %s..." % message)
	$HBoxContainer/message.text = message

# Randomly select a valid background for the loading screen
func update_background_image():
	$background.texture = Backgrounds[randi() % Backgrounds.size()]

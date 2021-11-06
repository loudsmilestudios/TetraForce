extends Control

var loading : bool = false
export(Array, Texture) var Backgrounds = [] # Array of valid background images

onready var message_label = $ProgressBar/VBoxContainer/message
onready var progress_bar = $ProgressBar
onready var background = $background

func _ready():
	self.hide()

# Displays and configures loading screen
func start_loading(initial_message = "TetraForce", init_percent = 0):
	set_loading_message(initial_message)
	update_background_image()
	$animation_player.play("loading")
	progress_bar.value = init_percent
	$logo.play()
	self.show()
	loading = true

# Hides loading screen and stops animations
func stop_loading(percent = null):
	$animation_player.stop()
	$logo.stop()
	loading = false
	if percent:
		progress_bar.value = percent
	self.hide()

# Starts loading if not already
func with_load(message = "Loading", percent = 0):
	if not loading:
		start_loading(message, percent)
	else:
		set_loading_message(message, percent)

# Update current loading message
func set_loading_message(message, percent = 0):
	print("Loading: %s..." % message)
	progress_bar.value = percent
	message_label.text = message

# Randomly select a valid background for the loading screen
func update_background_image():
	background.texture = Backgrounds[randi() % Backgrounds.size()]

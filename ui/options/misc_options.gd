extends Control

onready var censor_button = $VBoxContainer/CensorToggle

func _ready():
	global.connect("options_loaded", self, "update_options")
	censor_button.connect("pressed", self, "toggle_censor")

func toggle_censor():
	if censor_button.pressed:
		global.options.misc.censor = true
		sfx.play("sword0")
	else:
		global.options.misc.censor = false
		sfx.play("swordcharge")

func update_options():
	if not "misc" in global.options:
		global.options["misc"] = { 
			"censor" : true
		}
	
	if global.options.misc.censor:
		censor_button.pressed = true
	else:
		censor_button.pressed = false

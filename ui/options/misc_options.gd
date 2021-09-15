extends Control

onready var censor_button = $CensorButton

func _ready():
	global.connect("options_loaded", self, "update_options")
	censor_button.connect("button_down", self, "toggle_censor")

func toggle_censor():
	global.options.misc.censor = !global.options.misc.censor
	update_options()

func update_options():
	if not "misc" in global.options:
		global.options["misc"] = { 
			"censor" : true
		}
	
	if global.options.misc.censor:
		censor_button.text = "Disable Text Filter"
	else:
		censor_button.text = "Enable Text Filter"

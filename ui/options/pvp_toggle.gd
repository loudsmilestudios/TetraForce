extends Button

func _ready():
	global.connect("options_loaded", Callable(self, "update_options"))
	self.connect("pressed", Callable(self, "toggle_pvp"))

func toggle_pvp():
	
	if pressed:
		global.options["pvp"] = true
		sfx.play("sword0")
	else:
		global.options["pvp"] = false
		sfx.play("swordcharge")

func update_options():
	if not "pvp" in global.options or global.options["pvp"]:
		self.button_pressed = true
		global.pvp = true
	else:
		self.button_pressed = false
		global.pvp = false

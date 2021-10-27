extends Button

func _ready():
	global.connect("options_loaded", self, "update_options")
	self.connect("pressed", self, "toggle_pvp")

func toggle_pvp():
	
	if pressed:
		global.options["pvp"] = true
		sfx.play("sword0")
	else:
		global.options["pvp"] = false
		sfx.play("swordcharge")

func update_options():
	if not "pvp" in global.options or global.options["pvp"]:
		self.pressed = true
		global.pvp = true
	else:
		self.pressed = false
		global.pvp = false

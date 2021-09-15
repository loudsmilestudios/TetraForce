extends Button

func _ready():
	global.connect("options_loaded", self, "update_options")
	self.connect("button_down", self, "toggle_pvp")

func toggle_pvp():
	if not "pvp" in global.options:
		global.options["pvp"] = false
	else:
		global.options["pvp"] = !global.options["pvp"]
	update_options()

func update_options():
	if not "pvp" in global.options or global.options["pvp"]:
		self.text = "PvP: Enabled"
		global.pvp = true
	else:
		self.text = "PvP: Disabled"
		global.pvp = false

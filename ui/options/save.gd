extends Button

func _ready():
	self.connect("button_down", self, "_on_save_pressed")

func _on_save_pressed():
	sfx.play("sword3")
	global.save_options()

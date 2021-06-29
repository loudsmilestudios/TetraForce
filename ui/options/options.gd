extends TabContainer

func _ready():
	self.connect("tab_changed", self, "on_tab_changed")

func on_tab_changed(index = -1):
	sfx.play("sword3")

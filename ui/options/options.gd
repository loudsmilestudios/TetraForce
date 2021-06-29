extends TabContainer

func _ready():
	self.connect("tab_selected", self, "on_tab_selected")

func on_tab_selected(index = -1):
	sfx.play("sword3")

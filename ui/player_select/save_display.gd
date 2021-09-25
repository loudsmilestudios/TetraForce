class_name SaveDisplay
extends PanelContainer

signal action_complete
signal clicked



export(String) var save_name = null
export(Texture) var save_icon = null
var mode = 2

onready var button = $HBoxContainer/Button

func _ready():
	self.update_display()
	button.connect("button_down", self, "on_action")

func update_display():
	if save_name:
		self.name = save_name
		button.text = save_name
	if save_icon:
		button.icon = save_icon

func on_action():
	match mode:
		0:
			pass
		1:
			global.save_game_data(save_name)
			emit_signal("action_complete")
		2:
			if global.load_game_data(save_name):
				emit_signal("action_complete")
			else:
				printerr("Failed to load save: `%s`" % save_name)
		3:
			global.delete_save_data(save_name)
			self.queue_free()
		_:
			printerr("%s has an invalid SAVE_MODE value for `mode`!" % get_path())
	emit_signal("clicked")

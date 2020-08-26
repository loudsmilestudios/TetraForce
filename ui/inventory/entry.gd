extends Panel

var text = "" setget set_text
var selected = false setget set_selected

func set_text(value):
	text = value
	$label.text = value

func set_selected(value):
	selected = value
	if selected:
		grab_focus()
		self_modulate = Color(0.33, 0.33, 0.33, 1)
	else:
		self_modulate = Color(1, 1, 1, 1)

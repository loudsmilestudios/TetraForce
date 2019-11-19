tool
extends StaticBody2D

export(String, MULTILINE) var text: String = ""

func _ready() -> void:
	add_to_group("interact")
	add_to_group("nopush")

func interact(node):
	node.state = "busy"
	var dialog = preload("res://ui/dialog.tscn").instance()
	if text != "":
		dialog.text = text
	get_parent().add_child(dialog)
	yield(dialog, "finished")
	node.action_cooldown = 5
	node.state = "default"

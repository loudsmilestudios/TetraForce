extends StaticBody2D

export(String, MULTILINE) var file_name: String = ""

signal begin_dialogue

func _ready():
	add_to_group("interactable")

func interact(node):
	var dialogue = preload("res://ui/dialogue/dialogue_manager.tscn").instance()
	node.add_child(dialogue)
	connect("begin_dialogue", dialogue, "Begin_Dialogue")
	node.state = "menu"
	if file_name != "":
		dialogue.file_name = file_name
		emit_signal("begin_dialogue")


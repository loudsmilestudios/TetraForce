extends StaticBody2D

export(String, MULTILINE) var dialogue: String = ""

func _ready():
	add_to_group("interactable")
	add_to_group("nopush")

func interact(node):
	var dialogue_manager = preload("res://ui/dialogue/dialogue_manager.tscn").instance()
	node.add_child(dialogue_manager)
	node.state = "menu"
	dialogue_manager.file_name = dialogue
	dialogue_manager.Begin_Dialogue()


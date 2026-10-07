extends StaticBody2D

@export var dialogue: String = "" # (String, MULTILINE)

func _ready():
	add_to_group("interactable")
	add_to_group("nopush")

func interact(node):
	var dialogue_manager = preload("res://ui/dialogue/dialogue_manager.tscn").instantiate()
	node.add_child(dialogue_manager)
	node.state = "menu"
	dialogue_manager.file_name = dialogue
	dialogue_manager.Begin_Dialogue()


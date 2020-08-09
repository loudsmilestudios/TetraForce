extends StaticBody2D

export(String, MULTILINE) var file_name: String = ""

signal begin_dialogue

func _ready():
	add_to_group("interactable")
	yield(get_tree().create_timer(1),"timeout")
	connect("begin_dialogue", global.dialogueWindow, "Begin_Dialogue")

func interact(node):
	if file_name != "":
		global.dialogueWindow.file_name = file_name
		emit_signal("begin_dialogue")


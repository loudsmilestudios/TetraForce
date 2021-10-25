extends StaticBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("objects")
	add_to_group("interactable")

func interact(node):
	print("ye")
	if node is Player:
		node.hud.open_tournament(get_parent().name)
		
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

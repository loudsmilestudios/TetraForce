extends CanvasLayer

onready var text = $Control/Label

func _process(delta):
	text.text = str(network.player_list, "\n", network.current_players, "\n", get_tree().get_nodes_in_group("player"))

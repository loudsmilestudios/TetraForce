extends CanvasLayer

onready var text = $Control/Label

func _process(delta):
	text.text = str(
		"Player List: ", network.player_list,
		"\nMap Peers: ", network.map_peers,
		"\nMap Hosts: ", network.map_hosts,
		"\nPlayer Nodes: ", get_tree().get_nodes_in_group("player")
		)

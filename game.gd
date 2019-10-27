extends Node

func _ready():
	network.current_map = self
	add_child(preload("res://engine/camera.tscn").instance())
	add_child(preload("res://ui/hud.tscn").instance())
	add_new_player(get_tree().get_network_unique_id())
	
	network.update_maps()
	
	screenfx.play("fadein")

func add_new_player(id):
	var new_player = preload("res://player/player.tscn").instance()
	new_player.name = str(id)
	new_player.set_network_master(id, true)
	
	add_child(new_player)
	new_player.position = get_node("Spawn").position
	new_player.initialize()

func update_players():
	var player_nodes = get_tree().get_nodes_in_group("player")
	var map_peers = []
	for peer in network.map_peers:
		map_peers.append(peer)
	
	# first try to remove old players
	for player in player_nodes:
		var id = int(player.name)
		if !map_peers.has(id) && id != get_tree().get_network_unique_id():
			player.queue_free()
	
	# add player names to an array
	var player_names = []
	for player in player_nodes:
		player_names.append(int(player.name))
	
	# now try to add new players
	for id in map_peers:
		if !player_names.has(id):
			add_new_player(id)






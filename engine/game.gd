extends Node

signal player_entered

var camera = preload("res://engine/camera.tscn").instance()

func _ready():
	network.current_map = self
	add_child(camera)
	add_new_player(get_tree().get_network_unique_id())
	network.send_current_map() # starts player list updates
	screenfx.play("fadein")

func add_new_player(id):
	var new_player = preload("res://player/player.tscn").instance()
	new_player.name = str(id)
	new_player.set_network_master(id, true)
	
	add_child(new_player)
	new_player.camera = camera
	new_player.initialize()
	
	emit_signal("player_entered", id)

func remove_player(id):
	get_node(str(id)).queue_free()
	for node in get_tree().get_nodes_in_group(str(id)):
		node.queue_free()

func update_puppets():
	var player_nodes = get_tree().get_nodes_in_group("player")
	var player_names = []
	for player in player_nodes:
		# first remove old players
		var id = int(player.name)
		if !network.map_peers.has(int(id)) && id != get_tree().get_network_unique_id():
			remove_player(id)
		
		# add player names to array
		player_names.append(int(player.name))
	
	# match network peers to this new list of names
	for id in network.map_peers:
		if !player_names.has(id): # if there's fewer names than peers
			add_new_player(id) # add a new node for that name








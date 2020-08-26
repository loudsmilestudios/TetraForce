extends Node

signal player_entered

var camera = preload("res://entities/player/camera.tscn").instance()

func _ready():
	network.current_map = self
	add_child(camera)
	network.map_peers = []
	add_new_player(network.pid)
	for player in network.player_list.keys():
		if network.player_list[player] == name:
			add_new_player(player)
	# force the server to acknowledge this player's presence
	network.send_current_map() # starts player list updates
	screenfx.play("fadein")
	connect("player_entered", self, "player_entered")

func _process(delta): # can be on screen change instead of process
	if !network.is_map_host():
		return
	var visible_enemies: Array = []
	for entity_detect in get_tree().get_nodes_in_group("entity_detect"):
		if is_instance_valid(entity_detect):
			for entity in entity_detect.get_overlapping_bodies():
				if entity.is_in_group("enemy"):
					visible_enemies.append(entity)
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if visible_enemies.has(enemy):
			enemy.set_physics_process(true)
		else:
			enemy.set_physics_process(false)
			enemy.position = enemy.home_position

func add_new_player(id):
	var new_player = preload("res://entities/player/player.tscn").instance()
	new_player.name = str(id)
	new_player.set_network_master(id, true)
	
	var entity_detect = preload("res://entities/player/entity_detect.tscn").instance()
	entity_detect.player = new_player
	add_child(entity_detect)
	entity_detect.add_to_group(str(id))
	
	add_child(new_player)
	new_player.camera = camera
	new_player.initialize()
	
	if id == network.pid:
		new_player.sprite.texture = load(global.options.player_data.skin)
		new_player.nametag.text = global.options.player_data.name
	else:
		new_player.sprite.texture = load(network.player_data.get(id).skin)
		new_player.nametag.text = network.player_data.get(id).name

func remove_player(id):
	if has_node(str(id)):
		get_node(str(id)).queue_free()
	for node in get_tree().get_nodes_in_group(str(id)):
		node.queue_free()

func update_puppets():
	var player_nodes = get_tree().get_nodes_in_group("player")
	var player_names = []
	for player in player_nodes:
		# first remove old players
		var id = int(player.name)
		if !network.map_peers.has(int(id)) && id != network.pid:
			remove_player(id)
		
		# add player names to array
		player_names.append(int(player.name))
	
	# match network peers to this new list of names
	for id in network.map_peers:
		if !player_names.has(id): # if there's fewer names than peers
			add_new_player(id) # add a new node for that name

func player_entered(id):
	return
	if id != network.pid:
		print("player ", id, " entered")

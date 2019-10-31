extends Node

func _ready():
	network.current_map = self
	add_child(preload("res://engine/camera.tscn").instance())
	add_child(preload("res://ui/hud.tscn").instance())
	add_new_player(get_tree().get_network_unique_id())
	
	network.update_maps()
	
	screenfx.play("fadein")
	
	# defer these connections to make sure all elements are attached and ready
	call_deferred("_connect_transitions")

func _connect_transitions():
	# On these 2 signals, we want to check whether we want to activate enemies or not
	screenfx.connect("animation_finished", self, "_set_enemy_physics_processes")
	$Camera.connect("screen_change_completed", self, "_set_enemy_physics_processes")

func _set_enemy_physics_processes():
	var visible_enemies = []
	for entity_detect in get_tree().get_nodes_in_group("entity_detect"):
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
	var new_player = preload("res://player/player.tscn").instance()
	new_player.name = str(id)
	new_player.set_network_master(id, true)
	
	var entity_detect = preload("res://engine/entity_detect.tscn").instance()
	entity_detect.player = new_player
	add_child(entity_detect)
	
	add_child(new_player)
	new_player.position = get_node("Spawn").position
	new_player.initialize()
	
	if id == get_tree().get_network_unique_id():
		new_player.get_node("Sprite").texture = load(network.my_skin)
		new_player.texture_default = load(network.my_skin)
	else:
		new_player.get_node("Sprite").texture = load(network.player_skins.get(id))
		new_player.texture_default = load(network.player_skins.get(id))
	new_player.sync_all()

func remove_player(id):
	get_node(str(id)).queue_free()
	for node in get_tree().get_nodes_in_group(str(id)):
		node.queue_free()

func update_players():
	var player_nodes = get_tree().get_nodes_in_group("player")
	var map_peers = []
	for peer in network.map_peers:
		map_peers.append(peer)
	
	var player_names = []
	for player in player_nodes:
		# first try to remove old players
		var id = int(player.name)
		if !map_peers.has(id) && id != get_tree().get_network_unique_id():
			remove_player(id)
		
		# add player names to an array
		player_names.append(int(player.name))
		
		# sync player attributes
		player.sync_all()
	
	# now try to add new players
	for id in map_peers:
		if !player_names.has(id):
			add_new_player(id)






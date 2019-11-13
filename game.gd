extends Node

signal player_entered

var camera = preload("res://engine/camera.tscn").instance()

func _ready() -> void:
	network.current_map = self
	add_child(camera)
	add_child(preload("res://ui/hud.tscn").instance())
	add_new_player(get_tree().get_network_unique_id())
	
	network.update_maps()
	screenfx.play("fadein")
	
	if get_tree().is_network_server():
		network._send_flags_to_player(1)
	else:
		network.rpc_id(1, "_request_map_flags", get_tree().get_network_unique_id())
		

func _process(delta: float) -> void:
	var visible_enemies: Array = []
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

func add_new_player(id: int) -> void:
	var new_player = preload("res://player/player.tscn").instance()
	new_player.name = str(id)
	new_player.set_network_master(id, true)
	
	var entity_detect = preload("res://engine/entity_detect.tscn").instance()
	entity_detect.player = new_player
	add_child(entity_detect)
	
	add_child(new_player)
	new_player.initialize()
	
	if id == get_tree().get_network_unique_id():
		new_player.get_node("Sprite").texture = load(network.my_player_data.skin)
		new_player.texture_default = load(network.my_player_data.skin)
		new_player.set_player_label(network.my_player_data.name)

	else:
		new_player.get_node("Sprite").texture = load(network.player_data.get(id).skin)
		new_player.texture_default = load(network.player_data.get(id).skin)
		new_player.set_player_label(network.player_data.get(id).name)
	
	emit_signal("player_entered", id)

func remove_player(id: int) -> void:
	var r_node = get_node(str(id))
	if r_node:
		r_node.queue_free()
	for node in get_tree().get_nodes_in_group(str(id)):
		node.queue_free()

func update_players() -> void:
	var player_nodes: Array = get_tree().get_nodes_in_group("player")
	var map_peers: Array = []
	for peer in network.map_peers:
		map_peers.append(peer)
	
	var player_names: Array = []
	for player in player_nodes:
		# first try to remove old players
		var id: int = int(player.name)
		if !map_peers.has(id) && id != get_tree().get_network_unique_id():
			remove_player(id)
		
		# add player names to an array
		player_names.append(int(player.name))
	
	# now try to add new players
	for id in map_peers:
		if !player_names.has(id):
			add_new_player(id)

remote func spawn_subitem(dropped: String, pos: Vector2, subitem_name: String) -> void:
	var drop_instance = load(dropped).instance()
	drop_instance.name = subitem_name
	add_child(drop_instance)
	drop_instance.global_position = pos

remote func receive_chat_message(source: String, text: String) -> void:
	global.player.chat_messages.append({"source": source, "message": text})
	var chatBox = get_node("HUD/Chat")
	if chatBox:
		chatBox.add_new_message(source, text)

extends Node

var current_map = null

var active_maps = {}
var current_players = []
var map_owners = {}
var map_peers = []

var player_data = {}

var my_player_data = {
	skin ="res://player/player.png",
	name = "", 
	}

var clock

func _ready():
	set_process(false)
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

func initialize():
	clock = Timer.new()
	clock.wait_time = 0.1
	clock.one_shot = false
	clock.owner = self
	add_child(clock)
	clock.start()
	clock.connect("timeout", self, "clock_update")
	
	if get_tree().is_network_server():
		player_data[1] = my_player_data
	
	rpc_id(1, "_receive_my_player_data", get_tree().get_network_unique_id(), my_player_data)

remote func _receive_my_player_data(id, new_player_data):
	
	var collision_count = 0
	var player_name = new_player_data.name
	
	while check_dupe_name(player_name):
		collision_count += 1
		player_name = get_player_name(new_player_data.name, collision_count)
		
	new_player_data.name = player_name
	player_data[id] = new_player_data
	
	rpc("_receive_player_data", player_data)
	
func get_player_name(player_name, collision_count):
	if collision_count == 0:
		return player_name
	else:
		return player_name + "%d" % collision_count
	
func clear():
	if is_instance_valid(current_map):
		current_map.free()
	if is_instance_valid(clock):
		clock.stop()
	active_maps.clear()
	current_players.clear()
	map_owners.clear()
	map_peers.clear()

func check_dupe_name(player_name):
	for value in player_data.values():
		if player_name == value.name:
			return true
			
	return false

remote func _receive_player_data(received_player_data):
	player_data = received_player_data

func clock_update():
	update_maps()
	update_current_players()

func update_maps():
	if get_tree().is_network_server():
		active_maps[1] = current_map.name
		
		rpc("_receive_active_maps", active_maps)
		_update_map_owners()
	else:
		_send_current_map()
	
	update_current_players()
	current_map.update_players()

func update_current_players():
	var new_current_players = []
	for peer in active_maps:
		if active_maps.get(peer) == current_map.name:
			new_current_players.append(peer)
	var other_players = new_current_players
	other_players.erase(get_tree().get_network_unique_id())
	map_peers = other_players
	current_players = new_current_players

func _update_map_owners():
	for map in active_maps.values():
		if !map_owners.keys().has(map):
			map_owners[map] = active_maps.keys()[active_maps.values().find(map)]
	
	# remove old maps
	for map in map_owners.keys():
		if !active_maps.values().has(map):
			map_owners.erase(map)
	
	# reassign owners
	for map in map_owners.keys():
		var map_owner = map_owners.get(map) # gets player id of map
		if active_maps[map_owner] != map: # if player id is not in that map...
			map_owners[map] = active_maps.keys()[active_maps.values().find(map)] # change owner to a player in that map
	
	rpc("_receive_map_owners", map_owners)

# client only, sends current_map to server
func _send_current_map():
	rpc_id(1, "_receive_current_map", get_tree().get_network_unique_id(), current_map.name)

# server only, updates active_maps
remote func _receive_current_map(id, map):
	active_maps[id] = map
	rpc_id(id, "_receive_active_maps", active_maps)

# received by clients
remote func _receive_active_maps(maps):
	active_maps = maps

remote func _receive_map_owners(owners):
	map_owners = owners

func _player_connected(id):
	update_current_players()

func _player_disconnected(id):
	if get_tree().is_network_server():
		active_maps.erase(id)
	update_maps()

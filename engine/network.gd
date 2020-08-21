extends Node

var pid = 1

var dedicated = false

var current_map = null
var player_list = {} # player, map -- every active player and what map they're in
var map_hosts = {} # map, player -- every active map and which player is hosting it

var current_players = []
var map_peers = []

var tick
var tick_time = 0.05

signal end_aws_task
signal received_player_list

var player_data = {}

var states = {} # states[nodepath] = properties

func _ready():
	set_process(false)
	#get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

func initialize():
	tick = Timer.new()
	add_child(tick)
	tick.wait_time = tick_time # 1/20 of a second
	tick.one_shot = false
	tick.start()
	
	if get_tree().is_network_server() && !dedicated:
		player_data[1] = global.options.player_data
	else:
		pid = get_tree().get_network_unique_id()
		rpc_id(1, "_receive_my_player_data", global.options.player_data)

remote func _receive_my_player_data(data):
	var player_name = data.name
	var player_id = get_tree().get_rpc_sender_id()
	player_data[player_id] = data
	rpc("_receive_player_data", player_data)
	print(str(get_player_tag(player_id), " joined the game."))

remote func _receive_player_data(data):
	player_data = data

func get_player_tag(id):
	return str(player_data[id].name, " (", id, ")")

### PLAYER LIST UPDATES ###
# super important. list of every player in the game & what map they're in
#
# 1) client connects
# 2) client sends id and map to server
# 3) server adds id and map as a key/value pair in player_list dictionary
# 4) server sends player_list to every client
# 5) update_players() gives network.gd a list of all players in current room
#    and a list of all OTHER players in current room (current_players & map peers)
# 6) game.gd then takes this list of players, compares it to the player nodes
#    it has in the room, removes the ones that are no longer there, and adds
#    the ones that have just entered

func send_current_map(): # called when a player enters a new map
	if get_tree().is_network_server():
		if !dedicated:
			# server adds itself to the list and updates everyone
			_receive_current_map(1, current_map.name)
	else:
		# every one else first sends their information to the server, and then it updates everyone
		rpc_id(1, "_receive_current_map", pid, current_map.name)

remote func _receive_current_map(id, map): # server receives map from client
	player_list[id] = map
	update_players() # server updates its own map peers
	update_map_hosts()
	emit_signal("received_player_list")
	rpc("_receive_player_list", player_list, map_hosts)

remote func _receive_player_list(list, hosts): # client receives player list from server
	player_list = list
	map_hosts = hosts
	update_players() # client updates map peers
	emit_signal("received_player_list")

func update_players(): # gets list of all players in map AND all other players
	if dedicated:
		return
	current_players = []
	map_peers = []
	# get all players in current_map
	for id in player_list:
		if player_list.get(id) == player_list.get(pid):
			current_players.append(id)
	# get all players besides self in current_map
	for player in current_players:
		if player != pid:
			map_peers.append(player)
	
	# *** IMPORTANT *** #
	# this is where game.gd gets that information and updates the puppets
	current_map.update_puppets()
	
	# set network masters
	for node in get_tree().get_nodes_in_group("maphost"):
		node.set_network_master(map_hosts.get(network.current_map.name, pid))

func update_map_hosts():
	for map in player_list.values():
		if !map_hosts.keys().has(map):
			map_hosts[map] = player_list.keys()[player_list.values().find(map)]
	
	# remove old maps
	for map in map_hosts.keys():
		if !player_list.values().has(map):
			map_hosts.erase(map)
	
	# reassign owners
	for map in map_hosts.keys():
		var map_host = map_hosts.get(map)
		if player_list[map_host] != map || !player_list.keys().has(map_host):
			map_hosts[map] = player_list.keys()[player_list.values().find(map)]

func _player_disconnected(id): # remove disconnected players from player_list
	if get_tree().is_network_server():
		print(str(get_player_tag(id), " left the game."))
		player_list.erase(id)
		for map in map_hosts.keys():
			var map_host = map_hosts.get(map)
			if map_host == id:
				map_hosts[map] = player_list.keys()[player_list.values().find(map)]
		update_map_hosts()
		rpc("_receive_player_list", player_list, map_hosts)
		update_players()

func is_map_host():
	if !map_hosts.keys().has(current_map.name):
		return false
	if map_hosts.get(current_map.name) == pid:
		return true
	return false

func get_map_host():
	return map_hosts.get(current_map.name)

func set_state(object, properties):
	var nodepath = object.get_path()
	if pid == 1:
		states[nodepath] = properties
	else:
		rpc_id(1, "_receive_state_change", nodepath, properties)

remote func _receive_state_change(nodepath, properties):
	states[nodepath] = properties

func request_persistent_state(object):
	var nodepath = object.get_path()
	if pid == 1:
		var properties = states.get(nodepath, {})
		update_state(nodepath, properties)
	else:
		rpc_id(1, "_receive_state_request", nodepath)

remote func _receive_state_request(nodepath):
	var properties = states.get(nodepath, {})
	rpc_id(get_tree().get_rpc_sender_id(), "_receive_state", nodepath, properties)

remote func _receive_state(nodepath, properties):
	update_state(nodepath, properties)

func update_state(nodepath, properties):
	for property in properties.keys():
		get_node(nodepath).set(property, properties[property])

func peer_call(object, function, arguments = []):
	for peer in map_peers:
		rpc_id(peer, "_pc", object.get_path(), function, arguments)

func peer_call_unreliable(object, function, arguments = []):
	for peer in map_peers:
		rpc_unreliable_id(peer, "_pc", object.get_path(), function, arguments)

func peer_call_id(id, object, function, arguments = []):
	rpc_id(id, "_pc", object.get_path(), function, arguments)

func validate_object_id(id, object, question, function):
	rpc_id(id, "_check_object", object.get_path(), question, function)

remote func _check_object(object, question, function):
	if has_node(object) == question:
		rpc_id(get_tree().get_rpc_sender_id(), "_pc", object, function)

remote func _pc(object, function, arguments = []):
	if has_node(object):
		if get_node(object).has_method(function):
			get_node(object).callv(function, arguments)
		else:
			print("object ", get_node(object).name, " does not have method ", function)

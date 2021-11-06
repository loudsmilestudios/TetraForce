extends Node

const CONNECTION_TIMEOUT = 5

var pid = 1

var dedicated = false

var current_map = null
var player_list = {} # player, map -- every active player and what map they're in
var map_hosts = {} # map, player -- every active map and which player is hosting it

var validated_players = []
var current_players = []
var map_peers = []

var tick
var tick_time = 0.05

var empty_timeout = 0
var empty_timeout_timer

signal end_aws_task
signal received_player_list
signal refresh_player_request(player_id)

var player_data = {}
var player_identities = {}

var state

# save stuff
# states[nodepath] = properties
export var states = {
	weapons = [],
	items = [],
	pearl = [],
	collectables = [],
}

func _ready():
	set_process(false)
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	states.weapons = global.weapons
	states.items = global.items
	states.pearl = global.pearl



func clean_session_data():
	global.clean_session_data()
	current_players = []
	map_peers = []
	player_list = {}
	map_hosts = {}

func complete(include_network = true):
	tick.queue_free()
	current_map.queue_free()
	if include_network:
		get_tree().set_network_peer(null)
	clean_session_data()
	pid = 1

func initialize():
	tick = Timer.new()
	add_child(tick)
	tick.wait_time = tick_time # 1/20 of a second
	tick.one_shot = false
	tick.start()
	
	if get_tree().is_network_server() && !dedicated:
		player_data[1] = global.options.player_data
	elif !dedicated:
		pid = get_tree().get_network_unique_id()
		rpc_id(1, "_receive_my_player_token", IdentityService.my_identity.token)
		rpc_id(1, "_receive_my_player_data", global.options.player_data)
		rpc_id(1, "_receive_my_version", global.version)
	
	start_empty_timeout()
	
	yield(get_tree().create_timer(0.1), "timeout")
	
	global.emit_signal("debug_update")
	
remote func _get_system_arrays(state, value):
	#This is to update Arrays for Late Session Joins. Does Nothing, needs to be worked on
	states[state] = state
	match state:
			"weapons", "items", "pearl":
				pass

remote func _receive_my_player_token(token):
	var identity = IdentityService.load_token(token)
	var player_id = get_tree().get_rpc_sender_id()
	if not yield(identity.is_valid(), "completed"):
		kick_player(player_id, "Invalid identity token!")
	player_identities[player_id] = identity
	update_name_from_identity(player_id, identity)

func update_name_from_identity(player_id, identity):
	if identity.platform != "guest":
		if not player_id in player_data:
			player_data[player_id] = {}
		var new_name = "%s:%s" % [identity.platform, identity.display_name]
		_receive_name_update(player_id, new_name)
		peer_call(self, "_receive_name_update", [player_id, new_name])
			
remote func _receive_name_update(player_id, new_name):
	player_data[player_id].name = new_name
	emit_signal("refresh_player_request", player_id)

remote func _receive_my_player_data(data):
	var player_id = get_tree().get_rpc_sender_id()
	
	if player_id in player_data:
		data.name = player_data[player_id].name 
	var player_name = data.name
	
	if global.value_in_blacklist(player_name):
		player_name = global.filter_value(player_name)

	player_data[player_id] = data
	if player_id in player_identities and player_identities[player_id].loaded:
		update_name_from_identity(player_id, player_identities[player_id])
	rpc("_receive_player_data", player_data)
	print(str(get_player_tag(player_id), " joined the game."))

remote func _receive_my_version(version):
	if version != global.version:
		kick_player(get_tree().get_rpc_sender_id(), "Incompatible version! Server requires version: %s" % global.version)
	else:
		validated_players.append(get_tree().get_rpc_sender_id())

remote func _receive_player_data(data):
	player_data = data

func get_player_tag(id):
	return str(player_data[id].name, " (", id, ")")
	
func kick_player(id, reason):
	if is_network_master():
		print(get_player_tag(id), " kicked: ", reason)
		get_tree().network_peer.disconnect_peer(id, 1000, reason)
	else:
		print("Tried to kick as a client?")

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
	stop_empty_timeout()
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
		start_empty_timeout()
		for map in map_hosts.keys():
			var map_host = map_hosts.get(map)
			if map_host == id:
				map_hosts[map] = player_list.keys()[player_list.values().find(map)]
		update_map_hosts()
		rpc("_receive_player_list", player_list, map_hosts)
		update_players()

func _player_connected(id):
	if get_tree().is_network_server():
		start_connection_timeout(id)

func is_map_host():
	if not current_map:
		return false

	if !map_hosts.keys().has(current_map.name):
		return false
	if map_hosts.get(current_map.name) == pid:
		return true
	return false

func get_map_host():
	return map_hosts.get(current_map.name)
	
func persistent_set_state(object, properties):
	var nodepath = object
	if pid == 1:
		states[nodepath] = properties
		global.emit_signal("debug_update")
	else:
		rpc_id(1, "_receive_state_change", nodepath, properties)

remote func set_state(path, properties):
	if pid == 1:
		states[path] = properties
		rpc("_receive_state_array", path, properties)
		global.emit_signal("debug_update")
	else:
		rpc_id(1, "_receive_state_array", path, properties)

remote func add_to_state(state, value):
	if !states.get(state).has(value) || states.get(state).has("Spiritpearl"):
		states.get(state).append(value)
		global.set(state, states.get(state))
		rpc("_receive_state_change", state, states.get(state))
		set_state(state, states.get(state))

remote func _receive_state_change(nodepath, properties):
	states[nodepath] = properties
	global.emit_signal("debug_update")
	
remote func _receive_state_array(state, value):
	global.set(state, value)
	global.emit_signal("debug_update")

func request_persistent_state(object):
	var nodepath = str(object.get_path())
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

func peer_create_id(id, object_path, object_name, object_parent):
	rpc_id(id, object_path, object_name, object_parent)

func _create_object(object_path, object_name, object_parent):
	var new_object = load(object_path).instance()
	object_parent.add_child(new_object)
	new_object.name = object_name
	peer_call_id(get_tree().get_rpc_sender_id(), new_object.get_node("NetworkObject"), "update_enter_properties", [pid])

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

func start_empty_timeout():
	if empty_timeout == 0 || player_list.size() > 0 || empty_timeout_timer:
		#print("not starting empty_timeout timer")
		return
	
	print("starting empty_timeout timer")

	empty_timeout_timer = Timer.new()
	add_child(empty_timeout_timer)
	empty_timeout_timer.wait_time = empty_timeout
	empty_timeout_timer.connect("timeout", self, "_empty_timeout")
	empty_timeout_timer.start()

func stop_empty_timeout():
	if !empty_timeout_timer:
		#print("not stopping empty_timeout timer")
		return

	print("stopping empty_timeout timer")
	
	empty_timeout_timer.stop()
	remove_child(empty_timeout_timer)
	empty_timeout_timer = null

func _empty_timeout():
	print("empty_timeout timer timed out")
	if player_list.size() > 0:
		stop_empty_timeout()
		return
	
	print("no players after empty-server-timeout=%d, stopping server" % empty_timeout)
	get_tree().quit()

func start_connection_timeout(id):
	var connection_timer = Timer.new()
	connection_timer.name = "connection_timer_%s" % id
	connection_timer.connect("timeout", self, "_connection_timer_timeout", [id])
	add_child(connection_timer)
	connection_timer.start(CONNECTION_TIMEOUT)

func _connection_timer_timeout(id):
	var connection_timer = get_node_or_null("connection_timer_%s" % id)
	if connection_timer:
		if id in get_tree().get_network_connected_peers():
			if not id in validated_players:
				kick_player(id, "Did not recieve version data!")
			if not id in player_data:
				kick_player(id, "Did not recieve player data!")
			if not id in player_identities:
				kick_player(id, "Did not recieve player identity!")
		connection_timer.queue_free()
	else:
		if id in get_tree().get_network_connected_peers():
			kick_player(id, "Failed to find connection timer!")

extends Node

var network_object

var current_map = null
var player_list = {} # player, map -- every active player and what map they're in
var map_hosts = {} # map, player -- every active map and which player is hosting it

var current_players = []
var map_peers = []

signal received_player_list

var kick_list = {}

func _ready():
	set_process(false)
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

func start_kicks():
	if !get_tree().is_network_server():
		return
	var kick_timer = Timer.new()
	kick_timer.one_shot = false
	kick_timer.wait_time = 5
	add_child(kick_timer)
	kick_timer.connect("timeout", self, "check_kicks")
	kick_timer.start()

func check_kicks():
	for client in get_tree().get_network_connected_peers():
		if client == get_tree().get_network_unique_id():
			return
		if !kick_list.keys().has(client):
			kick_list[client] = false
		if kick_list[client] == true:
			print(client, " kicked due to inactivity")
			
			player_list.erase(client)
			update_players()
			update_map_hosts()
			
			network_object.disconnect_peer(client)
		else:
			kick_list[client] = true
			rpc_id(client, "_request_presence")

remote func _request_presence():
	rpc_id(1, "_acknowledge_presence", get_tree().get_network_unique_id())

remote func _acknowledge_presence(id):
	kick_list[id] = false

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
#

func send_current_map(): # called when a player enters a new map
	if get_tree().is_network_server():
		# server adds itself to the list and updates everyone
		_receive_current_map(1, current_map.name)
	else:
		# every one else first sends their information to the server, and then it updates everyone
		rpc_id(1, "_receive_current_map", get_tree().get_network_unique_id(), current_map.name)

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
	current_players = []
	map_peers = []
	# get all players in current_map
	for id in player_list:
		if player_list[id] == player_list[get_tree().get_network_unique_id()]:
			current_players.append(id)
	# get all players besides self in current_map
	for player in current_players:
		if player != get_tree().get_network_unique_id():
			map_peers.append(player)
	
	# *** IMPORTANT *** #
	# this is where game.gd gets that information and updates the puppets
	current_map.update_puppets()

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
		if player_list[map_host] != map:
			map_hosts[map] = player_list.keys()[player_list.values().find(map)]

func _player_disconnected(id): # remove disconnected players from player_list
	if get_tree().is_network_server():
		player_list.erase(id)
		rpc("_receive_player_list", player_list, map_hosts)
		update_players()

func is_map_host():
	if !map_hosts.keys().has(current_map.name):
		return false
	if map_hosts[current_map.name] == get_tree().get_network_unique_id():
		return true
	return false

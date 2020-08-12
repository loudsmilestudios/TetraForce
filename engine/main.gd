extends Control

export var default_port = 7777 # some random number, pick your port properly

var map = "res://maps/overworld.tmx"

var server_api = preload("res://engine/server_api.gd").new()

func _ready():
	get_tree().connect("connected_to_server", self, "_client_connect_ok")
	get_tree().connect("connection_failed", self, "_client_connect_fail")
	get_tree().connect("server_disconnected", self, "_client_disconnect")
	
	get_tree().set_auto_accept_quit(false)
	
	add_child(server_api)
	
	#For server commandline arguments. Searches for ones passed, then tries to set ones that exist.
	#Puts arguments passed as "--example=value" in a dictionary.
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
	#Checks if debug is true and exists as a passed command
	if("dedicatedserver" in arguments):
		if ((arguments.get("dedicatedserver")) == "true"):
			set_dedicated_server()
	#this overrides the default port of 7777
	if("port" in arguments):
		default_port = int(arguments["port"])
		get_node("panel/address").set_text("127.0.0.1:" + arguments["port"])
	
	if OS.get_name() == "Server":
		set_dedicated_server()

func start_game(dedicated = false):
	network.initialize()
	if dedicated:
		network.dedicated = true
	else:
		var level = load(map).instance()
		get_tree().get_root().add_child(level)
		hide()

func host_server(dedicated = false, port = default_port):
	var enet = NetworkedMultiplayerENet.new()
	enet.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	var err = enet.create_server(port, 16)
	if err != OK:
		print("Port in use")
		return
	get_tree().set_network_peer(enet)
	
	start_game(dedicated)

func join_server(ip, port):
	if !ip.is_valid_ip_address():
		print("Invalid IP")
		return
	
	var enet = NetworkedMultiplayerENet.new()
	enet.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	enet.create_client(ip, port)
	get_tree().set_network_peer(enet)

func join_aws(lobby_name):
	var lobby = yield(server_api.get_server(lobby_name), "completed")
	print(lobby)
	if lobby.success == true:
		join_server(lobby.data.ip, lobby.data.port)
	else:
		var new_lobby = yield(server_api.create_server(lobby_name), "completed")
		print(new_lobby)
		if new_lobby.success == true:
			join_aws(lobby_name)

func _client_connect_ok():
	start_game()

func _client_connect_fail():
	get_tree().set_network_peer(null)

func _client_disconnect():
	end_game()

func end_game():
	network.current_map.free() # erase immediately, otherwise network might show errors (this is why we connected deferred above)
	show()
	get_tree().set_network_peer(null) #remove peer

func set_dedicated_server():
	host_server(true)

func _notification(n):
	if (n == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		get_tree().set_network_peer(null)
		get_tree().quit()

func _on_connect_pressed():
	#print(yield(server_api.stop_server(lobby_name), "completed"))
	join_aws($aws/lobby.text)

func _on_host_pressed():
	host_server()

func _on_join_pressed():
	join_server(get_ipport()[0], int(get_ipport()[1]))

func get_ipport():
	return get_node("panel/address").get_text().rsplit(":")

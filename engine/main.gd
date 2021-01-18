extends Control

var default_map = "res://maps/shrine.tmx"
var default_entrance = "player_start"
export var default_port = 7777
var server_api = preload("res://engine/server_api.gd").new()

onready var address_line = $multiplayer/Manual/address
onready var lobby_line = $multiplayer/Automatic/lobby
onready var endpoint_button = $options/scroll/vbox/endpoint
onready var singleplayer_focus = $top/VBoxContainer/singleplayer

func _ready():
	$AnimatedSprite.playing = true
	global.load_options()
	hide_menus()
	$top.show()
	
	get_tree().connect("connected_to_server", self, "_client_connect_ok")
	get_tree().connect("connection_failed", self, "_client_connect_fail")
	get_tree().connect("server_disconnected", self, "_client_disconnect")
	network.connect("end_aws_task", self, "end_aws_task")
	
	get_tree().set_auto_accept_quit(false)
	
	add_child(server_api)
	
	endpoint_button.add_item("Production")
	endpoint_button.add_item("Stage")
	_on_endpoint_item_selected(0)
	
	if OS.get_name() == "HTML5":
		$multiplayer/Manual/host.disabled = true
	
	#For server commandline arguments. Searches for ones passed, then tries to set ones that exist.
	#Puts arguments passed as "--example=value" in a dictionary.
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
	
	if "map" in arguments:
		var map_arg = arguments.get("map").rsplit("/maps/")[1]
		var map_path = str("res://maps/", map_arg)
		default_map = map_path
		default_entrance = ""
		yield(get_tree(), "idle_frame")
		host_server(false, 0, 0, 1)
		
	
	#this overrides the default port of 7777
	if("port" in arguments):
		default_port = int(arguments["port"])
		get_node("panel/address").set_text("127.0.0.1:" + arguments["port"])
	
	if OS.get_name() == "Server" || arguments.get("dedicatedserver") == "true":
		var empty_timeout = get_empty_server_timeout(arguments)
		set_dedicated_server(empty_timeout)
	
	#print(yield(server_api.get_servers(), "completed"))
	
	yield(get_tree().create_timer(0.5), "timeout")
	sfx.set_music("shrine", "quiet")
	singleplayer_focus.grab_focus()

func get_empty_server_timeout(arguments):
	var empty_timeout
	
	var empty_timeout_arg = arguments.get("empty-server-timeout")   # don't set default here
	if empty_timeout_arg != null:
		if empty_timeout_arg.is_valid_integer():
			var empty_timeout_arg_int = int(empty_timeout_arg)
			if empty_timeout_arg_int >= 0:
				empty_timeout = empty_timeout_arg_int
			else:
				print("invalid value for empty-server-timeout - must be an integer >= 0")
		else:
			print("invalid value for empty-server-timeout - must be an integer >= 0")
	
	if empty_timeout == null:
		empty_timeout = 0   # set default here
		print("defaulting empty-server-timeout to %d" % empty_timeout)
	
	if empty_timeout > 0:
		print("empty-server-timeout set to %d seconds" % empty_timeout)
	else:
		print("empty-server-timeout set to 0 - server will not stop when empty")
	
	return empty_timeout

func start_game(dedicated = false, empty_timeout = 0):
	if dedicated:
		network.dedicated = true
		network.empty_timeout = empty_timeout
	
	network.initialize()
	
	if !dedicated:
		global.next_entrance = default_entrance
		var level = load(default_map).instance()
		get_tree().get_root().add_child(level)
		hide()

func host_server(dedicated = false, empty_timeout = 0, port = default_port, max_players = 16):
	var ws = WebSocketServer.new()
	var err = ws.listen(port, PoolStringArray(), true);
	get_tree().set_network_peer(ws)
	if err != OK:
		print("Port in use")
		return
	get_tree().set_network_peer(ws)
	
	start_game(dedicated, empty_timeout)

func join_server(ip, port):
	if !ip.is_valid_ip_address():
		print("Invalid IP")
		return
	
	var ws = WebSocketClient.new()
	var url = "ws://%s:%s" % [ip, port]
	ws.connect_to_url(url, PoolStringArray(), true);
	get_tree().set_network_peer(ws)

func join_aws(lobby_name):
	if screenfx.assigned_animation != "fadewhite":
		screenfx.play("fadewhite")
		yield(screenfx, "animation_finished")
	var lobby = yield(server_api.get_server(lobby_name), "completed")
	if lobby.success == true:
		join_server(lobby.data.ip, lobby.data.port)
	else:
		var new_lobby = yield(server_api.create_server(lobby_name), "completed")
		join_aws(lobby_name)

func end_aws_task(task_name):
	print(yield(server_api.stop_server(task_name), "completed"))

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

func quit_program():
	get_tree().set_network_peer(null)
	get_tree().quit()

func set_dedicated_server(empty_timeout):
	hide_menus()
	host_server(true, empty_timeout)

func get_ipport():
	return address_line.text.rsplit(":")

func hide_menus():
	for node in get_tree().get_nodes_in_group("menu"):
		node.hide()

func _notification(n):
	if (n == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
		quit_program()

func _on_connect_pressed():
	#print(yield(server_api.stop_server(lobby_line.text), "completed"))
	join_aws(lobby_line.text)

func _on_host_pressed():
	host_server(false)

func _on_join_pressed():
	join_server(get_ipport()[0], int(get_ipport()[1]))

func _on_quit_pressed():
	quit_program()

func _on_singleplayer_pressed():
	host_server(false, 0, 0, 1)

func _on_multiplayer_pressed():
	hide_menus()
	$multiplayer.show()
	$back.show()
	$back.grab_focus()

func _on_options_pressed():
	hide_menus()
	$options.show()
	$back.show()
	$back.grab_focus()

func _on_keybinds_pressed():
	hide_menus()
	$keybinds.show()
	$back.show()
	$back.grab_focus()

func _on_back_pressed():
	hide_menus()
	$top.show()
	singleplayer_focus.grab_focus()

func _on_save_pressed():
	global.save_options()

func _on_endpoint_item_selected(index):
	match index:
		0:
			server_api.api_endpoint = "api.online.tetraforce.io"
		1:
			server_api.api_endpoint = "stage.api.online.tetraforce.io"

func _on_mouse_entered():
	sfx.play("item_select")



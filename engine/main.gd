class_name Main
extends Control

var default_map = "res://maps/shrine.tmx"
var default_entrance = "player_start"
export var default_port = 7777
var server_api = preload("res://engine/server_api.gd").new()

onready var address_line = $multiplayer/Direct/address
onready var lobby_line = $multiplayer/Automatic/lobby
#onready var endpoint_button = $options/scroll/vbox/endpoint JosephB Needs to confirm deletion
onready var singleplayer_focus = $top/VBoxContainer/singleplayer
onready var loading_screen = $loading_screen_layer/loading_screen

func _ready():
	$AnimatedSprite.playing = true
	global.load_options()
	hide_menus()
	$top.show()
	
	get_tree().connect("connected_to_server", self, "_client_connect_ok")
	get_tree().connect("connection_failed", self, "_client_connect_fail")
	network.connect("end_aws_task", self, "end_aws_task")
	
	get_tree().set_auto_accept_quit(false)
	
	add_child(server_api)
	
	#endpoint_button.add_item("Production")
	#endpoint_button.add_item("Stage")
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

func start_game(dedicated = false, empty_timeout = 0, map = null, entrance = null):
	loading_screen.stop_loading()
	if dedicated:
		network.dedicated = true
		network.empty_timeout = empty_timeout
	
	network.initialize()
	
	if !dedicated:
		if entrance:
			global.next_entrance = entrance
		else:
			global.next_entrance = default_entrance
		var level
		if map:
			level = load(map).instance()
		else:
			level = load(default_map).instance()
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
	loading_screen.with_load("Connecting to host", 75)
	
	if !ip.is_valid_ip_address():
		print("Invalid IP")
		open_error_message("Invalid IP")
		loading_screen.stop_loading()
		return
	
	var ws = WebSocketClient.new()
	var url = "ws://%s:%s" % [ip, port]
	ws.connect("server_close_request", self, "_client_disconnect")
	ws.connect_to_url(url, PoolStringArray(), true);
	get_tree().set_network_peer(ws)

func join_aws(lobby_name):

	# Attempt to join existing server
	if not yield(attempt_to_join_aws_sever(lobby_name), "completed"):
		
		# Request new server
		loading_screen.with_load("Creating '%s'" % lobby_name, 25)
		var new_lobby = yield(server_api.create_server(lobby_name), "completed")
		print("API Response: %s" % new_lobby)
		
		# Handle response based on result
		if new_lobby.success:
			
			# Attempt to get server info 15 times
			for i in range(15):
				yield(get_tree().create_timer(8.0), "timeout")
				if yield(attempt_to_join_aws_sever(lobby_name, true), "completed"):
					return

			# Timeout if no sever info found
			print("Server creation timeout!")
			loading_screen.stop_loading()
			open_error_message("Server creation timeout!")
		else:
			loading_screen.stop_loading()
			open_error_message("Failed to create server: %s" % new_lobby.message)

func attempt_to_join_aws_sever(lobby_name, hide_loading_message = false) -> bool:
	if not hide_loading_message:
		loading_screen.with_load("Connecting to '%s'" % lobby_name, 0)

	var waitingOnServer = true

	while waitingOnServer:
		# Look up lobby
		var lobby = yield(server_api.get_server(lobby_name), "completed")
		print("API Response: %s" % lobby)
		
		# Return and act on result
		if lobby.success == true:
			if "status" in lobby.data:
				if lobby.data.status == "RUNNING":
					join_server(lobby.data.ip, lobby.data.port)
					return true
				elif lobby.data.status in ["PENDING", "PROVISIONING"]:
					loading_screen.with_load("'%s' pending" % lobby_name, 50)
					yield(get_tree().create_timer(5.0), "timeout")
				else:
					print("%s has status: %s", [lobby_name, lobby.data.status])
					waitingOnServer = false
			else:
				print("%s missing status!" % lobby_name)
				waitingOnServer = false
		else:
			waitingOnServer = false

	return false

func end_aws_task(task_name):
	print(yield(server_api.stop_server(task_name), "completed"))

func _client_connect_ok():
	loading_screen.stop_loading(100)
	start_game()

func _client_connect_fail():
	print("Failed to connect!")
	loading_screen.stop_loading()
	end_game()

func _client_disconnect(code, reason):
	print("Disconnected from server: %s, %s" % [code, reason])
	network.complete(false)
	show()
	if code != OK:
		open_error_message(reason)

func end_game():
	network.complete()
	show()
	screenfx.play("default")

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

func _on_quickstart_pressed():
	hide_menus()
	$top.show()
	singleplayer_focus.grab_focus()
	host_server(false, 0, 0, 1)

func open_error_message(message):
	hide_menus()
	$message/Label.text = message
	$message.show()
	$message/Button.grab_focus()

func _on_load_pressed():
	hide_menus()
	$player_select/saves.refresh_saves()
	$player_select.show()
	$player_select.show()
	$back.show()
	$back.grab_focus()

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

func _on_back_pressed():
	if $options.is_visible_in_tree():
		global.save_options()
	hide_menus()
	$top.show()
	singleplayer_focus.grab_focus()

func _on_returned_pressed():
	hide()

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




func _on_credits_pressed():
	hide_menus()
	$credits.show()
	$back.show()
	$back.grab_focus()

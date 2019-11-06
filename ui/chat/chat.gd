extends Panel

var message_log = []

func _ready():
	pass

func start():
	for entry in message_log:
		add_new_message(entry["source"], entry["message"])
	$IncomingMessages.scroll_to_line($IncomingMessages.get_line_count()-1)
	$EditMessage.grab_focus()

func add_new_message(source, text):
	$IncomingMessages.newline()
	$IncomingMessages.push_color(Color.cyan)
	$IncomingMessages.append_bbcode(source)
	$IncomingMessages.pop()
	$IncomingMessages.append_bbcode(": "+text)
	
func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		if is_typing():
			send_message_global(network.my_player_data.name, $EditMessage.text)
			$EditMessage.clear()
			$EditMessage.release_focus()
			$IncomingMessages.scroll_to_line($IncomingMessages.get_line_count()-1)
		else:
			$EditMessage.grab_focus()

func hide_all():
	self.visible = false
	
func show_all():
	self.visible = true

func send_message_global(source, text):
	print_debug("Marco")
	network.current_map.receive_chat_message(source, text)
	for peer in network.map_peers:
		network.current_map.rpc_id(peer, "receive_chat_message", source, text)
	
func is_typing():
	if $EditMessage.has_focus():
		return true
	return false

extends Panel

func _ready():
	pass

func start():
	$IncomingMessages.scroll_to_line($IncomingMessages.get_line_count())

func add_new_message(source, text):
	$IncomingMessages.newline()
	$IncomingMessages.push_color(Color.cyan)
	$IncomingMessages.append_bbcode(source)
	$IncomingMessages.pop()
	$IncomingMessages.append_bbcode(": "+text)
	$IncomingMessages.scroll_to_line($IncomingMessages.get_line_count()-1)
	
func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		if is_typing():
			send_message_global(network.my_player_data.name, $EditMessage.text)
			$EditMessage.clear()
			$EditMessage.release_focus()
		else:
			$EditMessage.grab_focus()
			
func hide_all():
	self.visible = false
	
func show_all():
	self.visible = true

func send_message_global(source, text):
	print_debug("Marco")
	for peer in network.map_peers:
		print_debug(peer)
		rpc_id(peer, "_receive_chat_message", source, text)
	
func is_typing():
	if $EditMessage.has_focus():
		return true
	return false

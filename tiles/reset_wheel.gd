extends StaticBody2D

export(String, MULTILINE) var dialogue: String = ""

var begin
var zone
var objects = []

func _ready():
	add_to_group("interactable")
	add_to_group("nopush")
	add_to_group("zoned")
	set_physics_process(false)
	yield(get_tree(), "idle_frame")
	for object in zone.get_objects():
		objects.append(object)
	
func _physics_process(delta):
	if zone.get_players() == []:
		yield(get_tree().create_timer(0.5), "timeout")
		if network.is_map_host():
			reset_object()
		else:
			network.peer_call_id(network.get_map_host(), self, "reset_object")
	
func interact(node):
	var dialogue_manager = preload("res://ui/dialogue/dialogue_manager.tscn").instance()
	var accept = dialogue_manager.get_node("DialogueUI/ChoiceBox/Button1")
	begin = accept
	accept.connect("pressed",self,"_on_Begin_Pressed")
	node.add_child(dialogue_manager)
	node.state = "menu"
	dialogue_manager.file_name = dialogue
	dialogue_manager.Begin_Dialogue()
	
func _on_Begin_Pressed():
	if begin.text == "Yes":
		if is_in_group("interactable"):
			remove_from_group("interactable")
			network.peer_call(self, "remove_from_group", ["interactable"])
		if network.is_map_host():
			reset()
		else:
			network.peer_call(self, "reset")
			
func reset():
	$AnimationPlayer.play("reset")
	network.peer_call($AnimationPlayer, "play", ["reset"])
	yield(get_tree().create_timer(1), "timeout")
	
	for player in zone.get_players():
		var id = int(player.name)
		if id == network.pid:
			reset_position(str(network.pid))
			continue
		network.peer_call_id(id, self, "reset_position", [str(id)])
	
	yield(get_tree().create_timer(0.5), "timeout")
	
	if network.is_map_host():
		reset_object()
	else:
		network.peer_call_id(network.get_map_host(), self, "reset_object")
	
	yield(get_tree().create_timer(2), "timeout")
	
	if !is_in_group("interactable"):
		add_to_group("interactable")
		network.peer_call(self, "add_to_group", ["interactable"])
	
func reset_position(id):
	var reset_position = Vector2(position.x, position.y + 16)
	var player = network.current_map.get_node(id)
	
	screenfx.play("fadewhite")
	yield(screenfx, "animation_finished")
	
	$AnimationPlayer.play("idle")
	network.peer_call($AnimationPlayer, "play", ["idle"])
	
	player.position = reset_position
	player.last_safe_pos = reset_position
	screenfx.play("fadein")
	
func reset_object():
	for object in objects:
		network.peer_call(object, "set_default_state", [zone])
		object.set_default_state(zone)



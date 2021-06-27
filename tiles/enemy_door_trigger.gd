extends StaticBody2D

export(String, MULTILINE) var dialogue: String = ""

var begin
var current_enemies = []
var zone

signal started
signal finished

func _ready():
	set_physics_process(false)
	add_to_group("interactable")
	add_to_group("nopush")
	add_to_group("zoned")

func _physics_process(delta):
	if zone:
		if zone.get_enemies() == []:
			deactivate()

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
	if begin.text == "Begin":
		if network.is_map_host():
			activate()
		else:
			network.peer_call_id(network.get_map_host(), self, "activate")
		
func activate():
	$AnimationPlayer.play("activate")
	network.peer_call($AnimationPlayer, "play", ["activate"])
	emit_signal("started")
	for i in range(20):
		yield(get_tree(), "idle_frame")
	set_physics_process(true)
	
	
func deactivate():
	$AnimationPlayer.play("deactivate")
	network.peer_call($AnimationPlayer, "play", ["deactivate"])
	remove_from_group("interactable")
	network.peer_call(self, "remove_from_group", ["interactable"])
	emit_signal("finished")
	set_physics_process(false)
	
	
	

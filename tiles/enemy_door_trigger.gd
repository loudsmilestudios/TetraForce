extends StaticBody2D

export(String, MULTILINE) var dialogue: String = ""

var begin
var zone

onready var active = false setget set_active
onready var disable = false setget set_disable
 
signal started
signal check_for_active
signal check_for_inactive
signal finished
signal reset

func _ready():
	set_physics_process(active)
	add_to_group("interactable")
	add_to_group("nopush")
	add_to_group("zoned")
	self.connect("check_for_active", self, "active")
	self.connect("check_for_inactive", self, "inactive")

func _physics_process(delta):
	if active && zone && network.is_map_host():
		if zone.get_enemies() == []:
			deactivate()
		if zone.get_players() == [] && zone.get_enemies() != []:
			deactivate()
			emit_signal("reset")
			add_to_group("interactable")
			network.peer_call(self, "add_to_group", ["interactable"])

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
	set_active(true)
	set_disable(true)
	emit_signal("started")
	for i in range(20):
		yield(get_tree(), "idle_frame")
	set_physics_process(true)
	
func active():
	if active == true && $AnimationPlayer.current_animation != "activate":
		$AnimationPlayer.play("active")
	set_disable(true)
	for i in range(20):
		yield(get_tree(), "idle_frame")
	set_physics_process(true)
	
func deactivate():
	$AnimationPlayer.play("deactivate")
	network.peer_call($AnimationPlayer, "play", ["deactivate"])
	set_active(false)
	set_disable(true)
	if zone.get_enemies() == []:
		emit_signal("finished")
	set_physics_process(false)
	
func inactive():
	if active == false && $AnimationPlayer.current_animation != "deactivate":
		$AnimationPlayer.play("inactive")
	for i in range(20):
		yield(get_tree(), "idle_frame")
	set_physics_process(false)
	set_disable(true)
	
func set_active(value):
	if active == value:
		return
	if network.is_map_host():
		network.peer_call(self, "set_active", [value])
	active = value
	if !active:
		emit_signal("check_for_inactive")
	else:
		emit_signal("check_for_active")
		
func set_disable(value):
	if disable == value:
		return
	if network.is_map_host():
		network.peer_call(self, "set_disable", [value])
	disable = value
	if !disable:
		add_to_group("interactable")
	else:
		if is_in_group("interactable"):
			remove_from_group("interactable")
	

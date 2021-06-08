extends StaticBody2D

export(String, MULTILINE) var dialogue: String = ""

var begin
var current_enemies = []
var active = false

func _ready():
	add_to_group("interactable")
	add_to_group("nopush")
		
func _physics_process(delta):
	if current_enemies == [] && active == true:
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
	active = true
	$AnimationPlayer.play("activate")
	network.peer_call($AnimationPlayer, "play", ["activate"])
	print(network.current_map.current_enemies)

func get_active_enemies(): # returns a list of all enemies in active zones
	var active_zones = [global.player.current_zone]
	var active_enemies = []
	for zone in active_zones:
		for enemy in zone.get_enemies():
			current_enemies.append(enemy)
	return current_enemies
	
func deactivate():
	$AnimationPlayer.play("deactivate")
	network.peer_call($AnimationPlayer, "play", ["deactivate"])
	

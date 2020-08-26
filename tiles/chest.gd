extends StaticBody2D

var opened = false setget set_open

export(String) var def = "weapon_def"
export(String) var item = "Bow"

signal update_persistent_state
signal begin_dialogue

func _ready():
	add_to_group("interactable")
	$Item.hide()

func interact(node):
	if opened:
		return
	
	if network.is_map_host():
		open()
	else:
		network.peer_call_id(network.get_map_host(), self, "open", [])
	
	node.state = "acquire"
	node.position = position + Vector2(0, 16)
	node.pos = node.position
	
	show_item()
	network.peer_call(self, "show_item")
	
	global.weapons.append(item)
	
	yield(get_tree().create_timer(1), "timeout")
	
	if global.get(def)[item].acquire != "":
		var dialogue = preload("res://ui/dialogue/dialogue_manager.tscn").instance()
		node.add_child(dialogue)
		connect("begin_dialogue", dialogue, "Begin_Dialogue")
		
		dialogue.file_name = global.get(def)[item].acquire
		emit_signal("begin_dialogue")
		yield(dialogue, "finished")
	
	hide_item()
	network.peer_call(self, "hide_item")
	
	node.spritedir = "Down"
	node.state = "default"

func show_item():
	$Item.texture = global.get(def)[item].icon
	$AnimationPlayer.play("open")

func hide_item():
	$AnimationPlayer.play("default")

func set_open(value):
	opened = value
	if opened:
		$Sprite.frame = 1

func open():
	network.peer_call(self, "set_open", [true])
	set_open(true)
	emit_signal("update_persistent_state")

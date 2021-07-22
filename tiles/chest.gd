extends StaticBody2D

var opened = false setget set_open
var monster_trigger = false setget set_spawned

export(String) var def = "weapon"
export(String) var item = "Bow"
export(String) var location = "room"
export(bool) var hidden = false

signal update_persistent_state
signal begin_dialogue

func _ready():
	add_to_group("interactable")
	$Item.hide()
	if hidden == true:
		hide()
		$CollisionShape2D.disabled = true

func interact(node):
	if opened:
		return
	if node.spritedir == "Up":
		if network.is_map_host():
				open()
		else:
			network.peer_call_id(network.get_map_host(), self, "open", [])
		
		sfx.play("itemfanfare", -5)
		node.state = "acquire"
		node.position = position + Vector2(0, 16)
		node.pos = node.position
		
		show_item()
		network.peer_call(self, "show_item")
		
		match def:
			"weapons", "items":
				network.add_to_state(def, item)
			"ammo":
				var ammo = global.get("ammo_def")[item]
				global.ammo[ammo.ammo_type] = global.ammo.get(ammo.ammo_type) + ammo.amount
				global.player.hud.update_weapons()
				global.player.hud.update_tetrans()
				print(ammo)
			"dungeon":
				network.current_map.get_node("dungeon_handler").add_key()
			"pearl":
				network.add_to_state(def, item)
		
		yield(get_tree().create_timer(1), "timeout")
		
		if global.get(str(def,"_def"))[item].acquire_dialogue != "":
			var dialogue = preload("res://ui/dialogue/dialogue_manager.tscn").instance()
			node.add_child(dialogue)
			connect("begin_dialogue", dialogue, "Begin_Dialogue")
			
			dialogue.file_name = global.get(str(def,"_def"))[item].acquire_dialogue
			emit_signal("begin_dialogue")
			yield(dialogue, "finished")
		
		hide_item()
		network.peer_call(self, "hide_item")
		
		node.spritedir = "Down"
		node.state = "default"

func show_item():
	$Item.texture = global.get(str(def,"_def"))[item].icon
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

func set_spawned(value):
	monster_trigger = value
	if monster_trigger:
		show()
		$CollisionShape2D.disabled = false
		
func chest_spawn():
			network.peer_call(self, "monster_trigger", [true])
			network.peer_call(self, "hidden", [false])
			set_spawned(true)
			hidden = false
			emit_signal("update_persistent_state")
			
	

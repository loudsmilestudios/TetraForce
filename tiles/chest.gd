extends StaticBody2D

var opened = false: set = set_open
var monster_trigger = false: set = set_spawned
var acquiring = false

@export var def: String = "weapons"
@export var item: String = "Bow"
@export var location: String = "room"
@export var is_hidden: bool = false

signal update_persistent_state
signal begin_dialogue

func _ready():
	add_to_group("interactable")
	$Item.hide()
	if is_hidden:
		hide()
		$CollisionShape2D.disabled = true

func interact(node):
	if opened or acquiring:
		return
	if node.spritedir == "Up":
		var definitions = global.get(str(def, "_def"))
		if not definitions is Dictionary or !definitions.has(item):
			push_error("Invalid chest item definition: %s/%s" % [def, item])
			return
		var item_data: Dictionary = definitions[item]
		var dungeon_handler = null
		if def == "dungeon":
			dungeon_handler = network.current_map.get_node_or_null("dungeon_handler")
			if !is_instance_valid(dungeon_handler):
				push_error("Key chest requires dungeon_handler in %s" % network.current_map.name)
				return
		acquiring = true
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
			"dungeon":
				dungeon_handler.add_key()
			"pearl":
				network.add_to_state(def, item)
		
		await get_tree().create_timer(1).timeout
		if !is_instance_valid(node):
			finish_acquisition(null)
			return
		
		if item_data.acquire_dialogue != "":
			var dialogue = preload("res://ui/dialogue/dialogue_manager.tscn").instantiate()
			node.add_child(dialogue)
			connect("begin_dialogue", Callable(dialogue, "Begin_Dialogue"))
			
			dialogue.file_name = item_data.acquire_dialogue
			emit_signal("begin_dialogue")
			await dialogue.finished
		
		finish_acquisition(node)

func finish_acquisition(node):
	hide_item()
	network.peer_call(self, "hide_item")
	acquiring = false
	if is_instance_valid(node) and node.state in ["acquire", "menu"]:
		node.spritedir = "Down"
		node.state = "default"

func show_item():
	$Item.texture = global.get(str(def,"_def"))[item].icon
	$AnimationPlayer.play("open")

func hide_item():
	$Item.hide()
	$AnimationPlayer.play("default")

func set_open(value):
	opened = value
	if opened:
		$Sprite2D.frame = 1

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
			network.peer_call(self, "set_spawned", [true])
			network.peer_call(self, "set_hidden", [false])
			set_spawned(true)
			set_hidden(false)
			emit_signal("update_persistent_state")

func set_hidden(value: bool):
	is_hidden = value
	visible = not value
	$CollisionShape2D.disabled = value
			
	

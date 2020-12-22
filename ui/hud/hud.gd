extends CanvasLayer

var player

const HEART_ROW_SIZE = 8
const HEART_SIZE = 8

onready var hud2d = $hud2d
onready var hearts = $hud2d/hearts
onready var buttons = $hud2d/buttons

func initialize(p):
	global.connect("debug_update", self, "debug_update")
	player = p
	player.connect("health_changed", self, "update_hearts")
	
	for i in player.MAX_HEALTH:
		var newheart = Sprite.new()
		newheart.texture = hearts.texture
		newheart.hframes = hearts.hframes
		hearts.add_child(newheart)
	update_hearts()
	update_weapons()
	update_tetrans()
	update_keys()
	update_buttons()
	Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")

func update_hearts():
	for heart in hearts.get_children():
		var index = heart.get_index()
		
		var x = (index % HEART_ROW_SIZE) * HEART_SIZE
		var y = (index / HEART_ROW_SIZE) * HEART_SIZE
		
		heart.position = Vector2(x,y)
		
		var lastheart = floor(player.health)
		if index > lastheart:
			heart.frame = 0
		if index == lastheart:
			heart.frame = (player.health - lastheart) * 4
		if index < lastheart:
			heart.frame = 4

func update_weapons():
	for button in buttons.get_children():
		button.get_node("icon").texture = null
		button.get_node("count").text = ""
		
		if global.equips[button.name] == "":
			continue
		
		var info = global.weapons_def[global.equips[button.name]]
		button.get_node("icon").texture = info.icon
		if info.ammo_type != "":
			button.get_node("count").text = str(global.ammo[info.ammo_type])

func update_tetrans():
	$tetrans/tetrans.text = str(global.ammo.tetrans).pad_zeros(3)

func update_keys():
	$keys.hide()
	if network.current_map.has_node("dungeon_handler"):
		$keys.show()
		$keys/keys.text = str(network.current_map.get_node("dungeon_handler").keys).pad_zeros(1)

func update_buttons():
	#Checks if there are any controllers connected
	if Input.get_connected_joypads().size() > 0:
		# Show controller buttons
		name = Input.get_joy_name(0)
		# If controller is XInput, show Xbox buttons
		if "XInput" in name or "Xbox" in name:
			for i in ["B", "X", "Y"]:
				get_node("hud2d/buttons/" + i).texture = preload("res://ui/hud/xbox_buttons.png")
		# If controller is DualShock, show PlayStation buttons
		elif "DualShock" in name or "PS" in name:
			for i in ["B", "X", "Y"]:
				get_node("hud2d/buttons/" + i).texture = preload("res://ui/hud/ps_buttons.png")
		else:
			for i in ["B", "X", "Y"]:
				get_node("hud2d/buttons/" + i).texture = preload("res://ui/hud/button_ui.png")
	else:
		# Show keyboard buttons
		for i in ["B", "X", "Y"]:
			get_node("hud2d/buttons/" + i).texture = preload("res://ui/hud/keyboard_buttons.png")

func show_hearts():
	hearts.modulate = lerp(hearts.modulate, Color(1,1,1,1), 0.1)

func hide_hearts():
	hearts.modulate = lerp(hearts.modulate, Color(1,1,1,0.33), 0.2)

func show_buttons():
	buttons.modulate = lerp(buttons.modulate, Color(1,1,1,1), 0.1)

func hide_buttons():
	buttons.modulate = lerp(buttons.modulate, Color(1,1,1,0.33), 0.2)

func show_inventory():
	var inventory = preload("res://ui/inventory/inventory.tscn").instance()
	add_child(inventory)
	#inventory.start()

func debug_update():
	$debug/states.text = JSON.print(network.states, "    ")

func _on_joy_connection_changed(dev_id, connected):
	if dev_id == 0:
		update_buttons()

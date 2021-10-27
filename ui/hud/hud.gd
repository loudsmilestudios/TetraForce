extends CanvasLayer

var player
var credits
var timer = Timer.new()
var max_pearls = 4
var spiritpearls = 0

const ESC_PATH = "res://ui/esc_menu/esc_menu.tscn"
const HEART_ROW_SIZE = 8
const HEART_SIZE = 8

onready var hud2d = $hud2d
onready var hearts = $hud2d/hearts
onready var buttons = $hud2d/buttons
onready var boss_overlay = $boss_overlay


func _ready():
	timer.connect("timeout",self,"on_slate_add") 
	timer.set_wait_time(0.25)
	add_child(timer)

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

	$hud2d/Z.modulate = Color(1,1,1,0.3)

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
	var node = ""
	var texture_name = ""
	var keyboard = false
	var hframes = 4
	var vframes = 4
	#Checks if there are any controllers connected
	if Input.get_connected_joypads().size() > 0:
		# Show controller buttons
		name = Input.get_joy_name(0)
		# If controller is XInput, show Xbox buttons
		if "XInput" in name or "Xbox" in name:
			texture_name = "xbox_buttons.png"
		# If controller is DualShock, show PlayStation buttons
		elif "DualShock" in name or "PS" in name:
			texture_name = "ps_buttons.png"
		else:
			texture_name = "switch_buttons.png"
	else:
		# Show keyboard buttons
		hframes = 1
		vframes = 1
		keyboard = true
		
	for i in ["B", "X", "Y"]:
		node = get_node("hud2d/buttons/" + i)
		update_key_icons_hud(keyboard, i, node, texture_name, hframes, vframes)
	
	# Update Confirm button
	node = $hud2d/Z
	update_key_icons_hud(keyboard, "A", node, texture_name, hframes, vframes)

func update_key_icons_hud(keyboard, button, node, texture_name, hframes, vframes):
	node.hframes = hframes
	node.vframes = vframes
	var input_size = InputMap.get_action_list(button).size() # Number of inputs mapped to each action
	if keyboard == true:
		node.frame = 0
		# Check every input in the action for a keyboard input
		for j in range(0,input_size):
			if InputMap.get_action_list(button)[j].get_class() == "InputEventKey":
				var name = InputMap.get_action_list(button)[j].scancode
				name = OS.get_scancode_string(name) + ".png"
				node.texture = load("res://ui/hud/keyboard/%s" % name)
	else:
		node.texture = load("res://ui/hud/%s" % texture_name)
		# Check every input in the action for a controller input
		for j in range(0,input_size):
			if InputMap.get_action_list(button)[j].get_class() == "InputEventJoypadButton":
				node.frame = InputMap.get_action_list(button)[j].get_button_index()

func show_hearts():
	hearts.modulate = lerp(hearts.modulate, Color(1,1,1,1), 0.1)

func hide_hearts():
	hearts.modulate = lerp(hearts.modulate, Color(1,1,1,0.33), 0.2)

func show_buttons():
	buttons.modulate = lerp(buttons.modulate, Color(1,1,1,1), 0.1)

func hide_buttons():
	buttons.modulate = lerp(buttons.modulate, Color(1,1,1,0.33), 0.2)
	
func show_action():
	$hud2d/Z.modulate = lerp($hud2d/Z.modulate, Color(1,1,1,1), 0.1)
	
func hide_action():
	$hud2d/Z.modulate = lerp($hud2d/Z.modulate, Color(1,1,1,0.3), 0.2)

func show_inventory():
	var inventory = preload("res://ui/inventory/inventory.tscn").instance()
	add_child(inventory)
	#inventory.start()

func on_full_slate():
	var newheart = Sprite.new()
	newheart.texture = hearts.texture
	newheart.hframes = hearts.hframes
	hearts.add_child(newheart)
	update_hearts()
	timer.start()
	
func on_slate_add():
	if global.player.health < global.max_health:
		global.player.health += 1
		sfx.play("blip")
		update_hearts()
	else:
		timer.stop()
	
func show_gameover():
	var gameover = preload("res://ui/layovers/gameover.tscn").instance()
	add_child(gameover)

func show_esc_menu():
	var esc_menu : Node = get_node_or_null("ESC_Menu")
	if esc_menu:
		player.state = "default"
		esc_menu.queue_free()
	else:
		player.state = "menu"
		esc_menu = preload(ESC_PATH).instance()
		add_child(esc_menu)

func debug_update():
	$debug/states.text = JSON.print(network.states, "    ")

func _on_joy_connection_changed(dev_id, connected):
	if dev_id == 0:
		update_buttons()

func play_credits():
	var credits = preload("res://ui/credits/CreditsCanvas.tscn").instance()
	add_child(credits)
	credits.connect("scroll_complete", credits, "queue_free")

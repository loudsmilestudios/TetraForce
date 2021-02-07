extends CanvasLayer

var player
var timer = Timer.new()

const HEART_ROW_SIZE = 8
const HEART_SIZE = 8

onready var hud2d = $hud2d
onready var hearts = $hud2d/hearts
onready var buttons = $hud2d/buttons
onready var pearl = preload("res://entities/collectables/spiritpearl.tscn").instance()

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
	
func collect_pearl():
	pearl.add_pearl()
	
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

func debug_update():
	$debug/states.text = JSON.print(network.states, "    ")

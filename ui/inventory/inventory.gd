extends Panel

onready var anim = $AnimationPlayer
onready var weapon_list = $scroll/weapons
onready var selected_icon = $display/selected_icon

var selected = 0

func _ready():
	get_parent().update_weapons()
	anim.play("slideup")
	sfx.play("inventory_open")

func start():
	update_pearls()
	add_weapons()
	yield(get_tree(), "physics_frame")
	change_selection(0)

func _input(event):
	if Input.is_action_just_pressed("UP"):
		sfx.play("item_select")
		change_selection(-1)
	if Input.is_action_just_pressed("DOWN"):
		sfx.play("item_select")
		change_selection(1)
	if Input.is_action_just_pressed("B"):
		sfx.play("inventory_equip")
		set_weapon("B")
	if Input.is_action_just_pressed("X"):
		sfx.play("inventory_equip")
		set_weapon("X")
	if Input.is_action_just_pressed("Y"):
		sfx.play("inventory_equip")
		set_weapon("Y")
	if Input.is_action_just_pressed("START"):
		sfx.play("inventory_close")
		get_parent().player.state = "default"
		get_parent().player.action_cooldown = 10
		anim.play("slidedown")

func change_selection(amt):
	selected = wrapi(selected + amt, 0, weapon_list.get_child_count())
	for entry in weapon_list.get_children():
		entry.selected = false
	weapon_list.get_child(selected).selected = true
	if weapon_list.get_child(selected).text == "------":
		selected_icon.texture = null
	else:
		selected_icon.texture = global.weapons_def[weapon_list.get_child(selected).text].icon

func add_weapons():
	for child in weapon_list.get_children():
		child.queue_free()
	for weapon_name in global.weapons:
		var new_entry = preload("res://ui/inventory/entry.tscn").instance()
		weapon_list.add_child(new_entry)
		new_entry.text = weapon_name
	while weapon_list.get_child_count() < 10:
		var new_entry = preload("res://ui/inventory/entry.tscn").instance()
		weapon_list.add_child(new_entry)
		new_entry.text = "------"

func set_weapon(btn):
	var old_selection = global.equips[btn]
	var new_selection = weapon_list.get_child(selected).text
	
	if weapon_list.get_child(selected).text == "------":
		new_selection = ""
	else:
		for key in global.equips.keys():
			if global.equips[key] == new_selection:
				global.equips[key] = old_selection
	
	global.equips[btn] = new_selection
	
	get_parent().update_weapons()
	
func update_pearls():
	var pearl_icon = $spiritpearl/pearl_icon
	pearl_icon.frame = pearl_icon.frame + global.pearl.size()
	$spiritpearl/pearl_qty.text = str("x",global.pearl.size())

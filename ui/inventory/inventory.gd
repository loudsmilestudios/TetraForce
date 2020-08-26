extends Panel

onready var anim = $AnimationPlayer
onready var weapon_list = $scroll/weapons
onready var selected_icon = $display/selected_icon

var selected = 0

func _ready():
	get_parent().update_weapons()
	anim.play("slideup")

func start():
	add_weapons()
	yield(get_tree(), "physics_frame")
	change_selection(0)

func _input(event):
	if Input.is_action_just_pressed("UP"):
		change_selection(-1)
	if Input.is_action_just_pressed("DOWN"):
		change_selection(1)
	if Input.is_action_just_pressed("B"):
		set_weapon("B")
	if Input.is_action_just_pressed("X"):
		set_weapon("X")
	if Input.is_action_just_pressed("Y"):
		set_weapon("Y")
	if Input.is_action_just_pressed("START"):
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
		selected_icon.texture = global.weapon_def[weapon_list.get_child(selected).text].icon

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

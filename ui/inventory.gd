extends Panel

onready var anim = $AnimationPlayer
onready var item_list = $scroll/items
onready var selected_icon = $display/selected_icon

var selected = 0

func _ready():
	update_equipped()
	anim.play("slideup")

func start():
	add_items()
	yield(get_tree(), "physics_frame")
	change_selection(0)

func _input(event):
	if Input.is_action_just_pressed("UP"):
		change_selection(-1)
	if Input.is_action_just_pressed("DOWN"):
		change_selection(1)
	if Input.is_action_just_pressed("B"):
		set_item("B")
	if Input.is_action_just_pressed("X"):
		set_item("X")
	if Input.is_action_just_pressed("Y"):
		set_item("Y")
	if Input.is_action_just_pressed("START"):
		get_parent().player.state = "default"
		get_parent().player.action_cooldown = 10
		anim.play("slidedown")

func change_selection(amt):
	selected = wrapi(selected + amt, 0, item_list.get_child_count())
	for entry in item_list.get_children():
		entry.selected = false
	item_list.get_child(selected).selected = true
	if item_list.get_child(selected).text == "------":
		selected_icon.texture = null
	else:
		selected_icon.texture = global.item_icons[item_list.get_child(selected).text]
	

func add_items():
	for child in item_list.get_children():
		child.queue_free()
	for item_name in global.items:
		var new_entry = preload("res://ui/entry.tscn").instance()
		item_list.add_child(new_entry)
		new_entry.text = item_name
	while item_list.get_child_count() < 10:
		var new_entry = preload("res://ui/entry.tscn").instance()
		item_list.add_child(new_entry)
		new_entry.text = "------"

func set_item(btn):
	var old_selection = global.equips[btn]
	var new_selection = item_list.get_child(selected).text
	
	if item_list.get_child(selected).text == "------":
		new_selection = ""
	else:
		for key in global.equips.keys():
			if global.equips[key] == new_selection:
				global.equips[key] = old_selection
	
	global.equips[btn] = new_selection
	
	update_equipped()

func update_equipped():
	$equipped.text = str(global.equips)

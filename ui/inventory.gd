extends Panel

onready var item_list = $scroll/items
onready var arrow = $arrow

func start():
	update_equipped()
	remove_child(arrow)
	add_items()

func _input(event):
	if Input.is_action_just_pressed("UP"):
		move_arrow(-1)
	if Input.is_action_just_pressed("DOWN"):
		move_arrow(1)
	if Input.is_action_just_pressed("B"):
		set_item("B")
	if Input.is_action_just_pressed("X"):
		set_item("X")
	if Input.is_action_just_pressed("Y"):
		set_item("Y")
	if Input.is_action_just_pressed("START"):
		get_parent().player.state = "default"
		get_parent().player.action_cooldown = 10
		queue_free()

func add_items():
	for item_name in global.items:
		var new_label = Label.new()
		item_list.add_child(new_label)
		new_label.owner = self
		new_label.text = "  " + item_name
		new_label.name = item_name
	item_list.get_child(0).add_child(arrow)

func set_item(btn):
	global.equips[btn] = arrow.get_parent().name
	update_equipped()

func update_equipped():
	$equipped.text = str(global.equips)

func move_arrow(dir):
	var current_label = item_list.get_children().find(arrow.get_parent())
	var new_label = wrapi(current_label + dir, 0, item_list.get_child_count())
	item_list.get_child(current_label).remove_child(arrow)
	item_list.get_child(new_label).add_child(arrow)

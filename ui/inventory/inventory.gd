extends Panel

onready var item_list = $ScrollContainer/Items
var arrow

var player

func start():
	update_equipped()
	
	arrow = Sprite.new()
	arrow.texture = preload("res://ui/inventory/inv_arrow.png")
	arrow.position = Vector2(10,14)
	arrow.scale = Vector2(2,2)
	
	add_items()

func add_items():
	for item_name in player.items:
		var new_label = Label.new()
		item_list.add_child(new_label)
		new_label.owner = self
		new_label.text = "  " + item_name
		new_label.name = item_name
	item_list.get_child(0).add_child(arrow)

func _input(event):
	if Input.is_action_just_pressed(controller.UP):
		move_arrow(-1)
	if Input.is_action_just_pressed(controller.DOWN):
		move_arrow(1)
	if Input.is_action_just_pressed(controller.B):
		set_item(controller.B)
	if Input.is_action_just_pressed(controller.X):
		set_item(controller.X)
	if Input.is_action_just_pressed(controller.Y):
		set_item(controller.Y)

func set_item(button):
	player.equip_slot[button] = arrow.get_parent().name
	update_equipped()

func update_equipped():
	$Equipped.text = str(player.equip_slot)

func move_arrow(dir):
	var current_label = item_list.get_children().find(arrow.get_parent())
	var new_label = wrapi(current_label + dir, 0, item_list.get_child_count())
	
	item_list.get_child(current_label).remove_child(arrow)
	item_list.get_child(new_label).add_child(arrow)

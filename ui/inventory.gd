extends Control

var selection = 0
var MAX_SELECT = 35

var has_item = []
var item_list = []
var cursor_position = 0

var cursor_node

func _ready():
	for i in range(MAX_SELECT+1):
		has_item.append(false)
	has_item[0] = true
	has_item[1] = true
	
	for child in get_child(0).get_child(0).get_child(0).get_children():
		if child.get_class() == "ReferenceRect":
			item_list.append(child.get_children())
	
	var item_counter = 0
	for row in item_list:
		for item in row:
			if !has_item[item_counter]:
				item.visible = false
			item_counter += 1
			
	cursor_node = get_child(0).get_child(0).get_child(0).get_child(0)
	pass

func update_cursor_loc():
	var column_selected = cursor_position%6
	var row_selected = floor(cursor_position/6)
	var item_selected = item_list[row_selected][column_selected]
	var parent_pos = item_selected.get_parent()
	var new_pos = item_selected.rect_position + parent_pos.rect_position
	new_pos.x -= 2
	new_pos.y -= 2
	cursor_node.rect_position = new_pos
	
func _process(delta):
	if Input.is_action_just_pressed("RIGHT"):
		cursor_position = min(cursor_position + 1, MAX_SELECT)
		update_cursor_loc()
	elif Input.is_action_just_pressed("LEFT"):
		cursor_position = max(cursor_position - 1, 0)
		update_cursor_loc()
	elif Input.is_action_just_pressed("UP"):
		cursor_position = max(cursor_position - 6, 0)
		update_cursor_loc()
	elif Input.is_action_just_pressed("DOWN"):
		cursor_position = min(cursor_position + 6, MAX_SELECT)
		update_cursor_loc()
	pass

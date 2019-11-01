extends Control

# These get sent by player.gd
var MAX_SELECT
var has_item = []


var selection = 0
var item_list = []
var cursor_position = 0

var equip_slot = {"X": -1, "Y": -1, "A": 0, "B": -1}

var cursor_node
var equip_nodes = []

func _ready():
	
	for child in get_child(0).get_child(0).get_child(0).get_child(0).get_children():
		if child.get_class() == "ReferenceRect":
			item_list.append(child.get_children())
	
	var item_counter = 0
	for row in item_list:
		for item in row:
			if !has_item[item_counter]:
				item.visible = false
			item_counter += 1
			
	for eq in range(4):
		equip_nodes.append(get_child(0).get_child(0).get_child(0).get_child(1 + eq))
	
	for eq in equip_nodes:
		if equip_slot[eq.name[5]] == -1:
			eq.visible = false
	cursor_node = get_child(0).get_child(0).get_child(0).get_child(0).get_child(0)
	
	pass
	
func scroll_down(player):
	has_item = player.has_item
	equip_slot = player.equip_slot
	player.get_parent().add_child(self)
	
func scroll_up(player):
	player.state = "default"
	player.get_parent().remove_child(self)

func update_cursor_loc():
	var column_selected = cursor_position%6
	var row_selected = floor(cursor_position/6)
	var item_selected = item_list[row_selected][column_selected]
	var parent_pos = item_selected.get_parent()
	var new_pos = item_selected.rect_position + parent_pos.rect_position
	new_pos.x -= 2
	new_pos.y -= 2
	cursor_node.rect_position = new_pos
	
func update_equipment(slot):
	var col
	var row
	var copy_node
	var cur_node = 0
	
	var count = 0
	for switch in equip_slot.values():
		if switch == cursor_position && slot != equip_slot.keys()[count]:
			equip_slot[equip_slot.keys()[count]] = equip_slot[slot]
			break
		count += 1
		
	equip_slot[slot] = cursor_position
	for slot in equip_slot.values():
		if slot >= 0 && has_item[slot]:
			col = slot%6
			row = floor(slot/6)
			var enode = equip_nodes[cur_node].get_child(0)
			enode.texture = item_list[row][col].get_child(0).texture
			enode.get_parent().visible = true
		else:
			equip_nodes[cur_node].visible = false
			equip_slot[equip_slot.keys()[cur_node]] = -1
		cur_node += 1
	
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
	elif Input.is_action_just_pressed("A"):
		update_equipment("A")
	elif Input.is_action_just_pressed("B"):
		update_equipment("B")
	elif Input.is_action_just_pressed("X"):
		update_equipment("X")
	elif Input.is_action_just_pressed("Y"):
		update_equipment("Y")
		
	pass

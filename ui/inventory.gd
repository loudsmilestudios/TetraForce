extends Control

var selection = 0
var MAX_SELECT = 35

var has_item = []
var item_list = []

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
	pass

func _process(delta):
	if Input.is_action_just_pressed("RIGHT"):
		print_debug("pressed right")

extends Node2D

class_name ItemGiver

var item_dictionary = {
	"moneyS": "res://droppables/rupee.tscn",
	"heart": "res://droppables/heart.tscn"
}

#func _init(node, item_name):
#	give_item(node, item_name)
	
func give_item(player_node, item_name):
	var item = _find_item(item_name)
	if !player_node || !item:
		return false
	
	item.pickup(player_node)
	return item

func _find_item(item_name):
	if item_dictionary.has(item_name):
		var item = load(item_dictionary[item_name])
		return item.instance()
	return null

func write_dialog(player_node, text):
	player_node.state = "busy"
	var dialog = preload("res://ui/dialog.tscn").instance()
	if text != "":
		dialog.text = text
	player_node.get_parent().add_child(dialog)
	yield(dialog, "finished")
	player_node.action_cooldown = 5
	player_node.state = "default"

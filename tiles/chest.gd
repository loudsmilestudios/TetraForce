tool
extends StaticBody2D

export(String) var item_name = ""

var opened = false

func _ready():
	add_to_group("interact")
	add_to_group("nopush")

func interact(node):
	if opened:
		return

	var ItemGiver = load("res://engine/ItemGiver.gd")
	var giver = ItemGiver.new()
	
	if !giver.give_item(node, item_name):
		giver.write_dialog(node, "The lid is stuck")
		return
	
	$Sprite.region_rect = Rect2(16, 0, 16, 16)
	opened = true

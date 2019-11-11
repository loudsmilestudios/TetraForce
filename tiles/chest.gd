tool
extends StaticBody2D

export(String) var item_name = ""
export(String, MULTILINE) var message = ""

var opened = false

func _ready():
	add_to_group("interact")
	add_to_group("nopush")

func open_chest(texture_path, doanim = false):
	$Sprite.region_rect = Rect2(16, 0, 16, 16)
	opened = true
	if doanim:
		play_anim(texture_path)
	
func play_anim(texture):
	var item_spr = Sprite.new()
	item_spr.texture = load(texture)
	global.player.get_parent().add_child(item_spr)
	item_spr.position = self.position + Vector2(0, -8)
	
	var float_anim = Tween.new()
	float_anim.interpolate_property(item_spr, "position", self.position + Vector2(0, 0), self.position + Vector2(0, -16), .6, Tween.TRANS_QUAD, Tween.EASE_OUT)
	float_anim.connect("tween_all_completed", item_spr, "queue_free")
	
	global.player.get_parent().add_child(float_anim)
	float_anim.start()
	
func interact(node):
	print_debug("ID:", get_name(), get_parent().get_name())
	if opened:
		return

	var ItemGiver = load("res://engine/ItemGiver.gd")
	var giver = ItemGiver.new()

	var item_instance = giver.give_item(node, item_name)
	if !item_instance:
		giver.write_dialog(node, "The lid is stuck.")
		return
		
	open_chest(item_instance.get_child(0).texture.resource_path, true)
	network.current_map.rpc("net_open_chest", get_path(), item_instance.get_child(0).texture.resource_path, true)
	
	item_instance.pickup(node)
	giver.write_dialog(node, message)

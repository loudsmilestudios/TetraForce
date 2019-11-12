tool

#Instance this class if you need flags synced over network.
extends NetworkObject

#Export these values, will be getting them from Tiled
export(String) var item_name = ""
export(String, MULTILINE) var message = ""

#The item inside the chest
var contained_item

#Seems cleanest to declare your network flags as an enum
enum Flag {OPENED}

func _ready():
	#Can interact with, cant push
	add_to_group("interact")
	add_to_group("nopush")
	
	#Tell NetworkObject that we want P1(Server host) to keep track of these globally as opened.
	is_server_managed = true
	#If you dont expecitly set this to true it will only send flags to players on
	#current map. Okay if we dont mind instances resetting when everyone leaves.
	
	#Initialize flag to false, will not broadcast this flag until a change is made to it
	net_set_flag(Flag.OPENED, false)
	
#This will run whenever a flag is about to be changed.
#Value is the incoming change
#net_get_flag() will return previous value until after this is run.
func _received_flag_update(flag, value):
	match flag:
		Flag.OPENED:
			if value == true:
				open_chest()

#Flip sprite to open
func open_chest():
	$Sprite.region_rect = Rect2(16, 0, 16, 16)

#Plays little sprite coming out of chest
func play_anim():
	var item_spr = Sprite.new()
	item_spr.texture = load(contained_item.get_child(0).texture.resource_path)
	global.player.get_parent().add_child(item_spr)
	item_spr.position = self.position + Vector2(0, -8)
	
	var float_anim = Tween.new()
	float_anim.interpolate_property(item_spr, "position", self.position + Vector2(0, 0), self.position + Vector2(0, -16), .6, Tween.TRANS_QUAD, Tween.EASE_OUT)
	float_anim.connect("tween_all_completed", item_spr, "queue_free")
	
	global.player.get_parent().add_child(float_anim)
	float_anim.start()

#Called when the player interacts with this object.
func interact(player_node):
	if net_get_flag(Flag.OPENED):
		return

	#ItemGiver is used to handle items based on the item_dictionary keys
	var ItemGiver = load("res://engine/ItemGiver.gd")
	var giver = ItemGiver.new()

	#Give item to player, returns null if invalid name
	contained_item = giver.give_item(player_node, item_name)
	if !contained_item:
		giver.write_dialog(player_node, "The lid is stuck.")
		return
	
	#Go ahead and handle the chest's state locally
	open_chest()
	play_anim()
	
	#Set the opened flag to true, this will sync where needed.
	net_set_flag(Flag.OPENED, true)
	
	#Use item giver to write message attached to object from tiled
	giver.write_dialog(player_node, message)

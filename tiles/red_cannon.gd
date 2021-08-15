extends StaticBody2D

var fired = false setget set_fired

export(String) var location = "room"

signal update_persistent_state

func _ready():
	if !fired:
		add_to_group("interactable")
	
func interact(node : Entity):
	var thorn_order = network.current_map.get_node("dungeon_handler").thorn_order
	var thornwall = get_parent().get_node(location + str(thorn_order))
	
	if node.spritedir == "Left":
		return
		
	if fired == false:
		if network.current_map.has_node("dungeon_handler"):
				network.current_map.get_node("dungeon_handler").add_thorn_order()
		$AnimationPlayer.play("fuse")
		network.peer_call($AnimationPlayer, "play", ["fuse"])
		node.state = "menu"
		node.add_to_group("invunerable")
		yield($AnimationPlayer, "animation_finished")
		
		$AnimationPlayer.play("shot")
		network.peer_call($AnimationPlayer, "play", ["shot"])
		
		if network.is_map_host():
			fire()
		else:
			network.peer_call_id(network.get_map_host(), self, "fire")
		yield($AnimationPlayer, "animation_finished")
		
		screenfx.play("fadewhite")
		yield(screenfx, "animation_finished")
		
		node.camera.unlimit()
		node.camera.target = thornwall
		thornwall.on_cannon_fired()
		
func set_fired(value):
	fired = value
	
func fire():
	network.peer_call(self, "set_fired", [true])
	set_fired(true)
	if is_in_group("interactable"):
		remove_from_group("interactable")
	emit_signal("update_persistent_state")

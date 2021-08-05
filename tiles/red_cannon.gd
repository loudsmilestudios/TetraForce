extends StaticBody2D

var fired = false
var player

export(String) var location = "room"

signal update_persistent_state

func _ready():
	add_to_group("interactable")
	
func _physics_process(delta):
	pass
	
func interact(node : Entity):
	player = node
	if node.spritedir == "Left":
		return
	if network.is_map_host():
		on_interact()
	else:
		network.peer_call_id(network.get_map_host(), self, "on_interact")
	
func on_interact():
	if fired == false:
		if network.is_map_host():
			network.peer_call(self, "on_interact")
		$AnimationPlayer.play("fuse")
		yield(get_tree().create_timer(2.5), "timeout")
		$AnimationPlayer.play("shot")
		yield($AnimationPlayer, "animation_finished")
		camera_pan()
		fired = true
		emit_signal("update_persistent_state")
		
func camera_pan():
	var thornwall = get_parent().get_node(location)
	print(thornwall.position)
	player.camera.unlimit()
	player.camera.position = thornwall.position

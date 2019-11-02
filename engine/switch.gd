extends Node2D
class_name Switch

signal on_activate
signal on_deactivate

export(int, "one_shot", "toggle", "time_out") var mode: int = 0
export(float) var cooldown: float = 5

var activated: bool = false

# Called in subclasses to update the state on the client or the server.
func update_state():
	var new_state = !activated
	
	# Call the state change function locally then remotely.
	change_state(new_state)
	for peer in network.map_peers:
		rpc_id(peer, "update_remote_state", new_state)

remote func update_remote_state(new_state: bool):
	change_state(new_state)

func change_state(new_state: bool):
	
	# Oneshot mode
	if mode == 0:
		if !activated:
			activated = true
			emit_signal("on_activate")
	
	# Toggle mode
	elif mode == 1:
		activated = new_state
		# Test the new state then emit the appropriate signal.
		if activated:
			emit_signal("on_activate")
		else:
			emit_signal("on_deactivate")
	
	# Timeout mode
	elif mode == 2:
		
		# If not activated, activate then start the cooldown timer.
		if !activated:
			activated = true
			emit_signal("on_activate")
			$CooldownTimer.start(cooldown)
	
	_update_sprite()

# Called when the sprite needs to be changed to reflect an updated state.
# Override this in subclasses.
func _update_sprite():
	pass

# Deactivate the switch once the TimeoutTimer is finished.
func finish_cooldown():
	activated = false
	emit_signal("on_deactivate")
	_update_sprite()
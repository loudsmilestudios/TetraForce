extends Node2D
class_name Switch

signal on_activate
signal on_deactivate

export(int, "one_shot", "toggle", "time_out") var mode: int = 0
export(float) var cooldown: float = 5

var activated: bool = false
var locked: bool = false

func _ready():
	get_parent().connect("player_entered", self, "sync_new_player")
	z_index = -10

# Called in subclasses to update the state on the client or the server.
func update_state():
	if is_scene_owner():
		var new_state = !activated
	
		# Call the state change function locally then remotely.
		change_state(new_state)
		for peer in network.map_peers:
			rpc_id(peer, "change_state", new_state)
			

# Locks the switch and prevents state change.
func lock():
	locked = true
	$CooldownTimer.paused = true

# Unlocks the switch and re-enables state change.
func unlock():
	locked = false
	$CooldownTimer.paused = false

func sync_new_player(id):
	if is_scene_owner():
		rpc_id(id, "sync_remote_state", activated, $CooldownTimer.time_left, locked)
		

remote func sync_remote_state(state: bool, time: float, should_lock: bool):
	activated = state
	_update_sprite()
	if time > 0.0 && mode == 2:
		$CooldownTimer.start(time)
	
	if should_lock:
		lock()
	else:
		unlock()

#Changing the state here.
remote func change_state(new_state: bool):
	
	# Oneshot mode
	if mode == 0:
		if !activated && !locked:
			activated = true
			emit_signal("on_activate")
	
	# Toggle mode
	elif mode == 1:
		if !locked:
			activated = new_state
			# Test the new state then emit the appropriate signal.
			if activated:
				emit_signal("on_activate")
			else:
				emit_signal("on_deactivate")
	
	# Timeout mode
	elif mode == 2:
		
		# If not activated, activate then start the cooldown timer.
		if !activated && !locked:
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
	if is_scene_owner():
		timeout()
	
		for peer in network.map_peers:
			rpc_id(peer, "timeout")

remote func timeout():
	activated = false
	emit_signal("on_deactivate")
	_update_sprite()

func is_scene_owner() -> bool:
	if !network.map_owners.keys().has(network.current_map.name):
		return false
	if network.map_owners[network.current_map.name] == get_tree().get_network_unique_id():
		return true
	return false

extends Node2D
class_name Switch

signal on_activate
signal on_deactivate

export(int, "one_shot", "toggle", "time_out") var mode: int = 0
export(float) var cooldown: float = 0.1

var activated: bool = false
var on_cooldown: bool = false

func update_state():
	var new_state = !activated
	
	change_state(new_state)
	for peer in network.map_peers:
		rpc_id(peer, "update_remote_state", new_state)

remote func update_remote_state(new_state: bool):
	change_state(new_state)

func change_state(new_state: bool):
	
	if mode == 0:
		if !activated:
			activated = true
			emit_signal("on_activate")
		
	elif mode == 1:
		
		if !on_cooldown:
			activated = new_state
			
			if activated:
				emit_signal("on_activate")
			else:
				emit_signal("on_deactivate")
			
			on_cooldown = true
			$CooldownTimer.start(cooldown)
		
	elif mode == 2:
		
		if !activated:
			activated = true
			on_cooldown = true
			emit_signal("on_activate")
			$CooldownTimer.start(cooldown)
	
	_update_sprite()

func _update_sprite():
	pass

func finish_cooldown():
	on_cooldown = false
	
	if mode == 2:
		activated = false
		emit_signal("on_deactivate")
		_update_sprite()

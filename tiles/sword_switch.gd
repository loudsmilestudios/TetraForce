extends Node2D

signal on_activate
signal on_deactivate

export(int, "one_shot", "toggle", "time_out") var mode: int = 0

export(bool) var one_shot: bool = false

var activated: bool = false
var on_cooldown: bool = false

func _ready():
	pass

func _physics_process(delta):
	pass

func _on_HitBox_area_entered(area: Area2D):
	var sprite = $Sprite
	
	if mode == 0:
		if !activated:
			activated = true
			sprite.frame_coords.x = 1
			emit_signal("on_activate")
			update_remote("enable_remote")
			
	elif mode == 1:
		
		if !on_cooldown:
			activated = !activated
			
			if activated:
				sprite.frame_coords.x = 1
				emit_signal("on_activate")
				update_remote("enable_remote")
				
			else:
				sprite.frame_coords.x = 0
				emit_signal("on_deactivate")
				update_remote("disable_remote")
			
			$CooldownTimer.start()
			on_cooldown = true

func _on_CooldownTimer_timeout():
	on_cooldown = false
	
	for peer in network.map_peers:
		rpc_id(peer, "remote_cooldown_timeout")

func update_remote(function: String):
	for peer in network.map_peers:
		rpc_id(peer, function)

remote func enable_remote():
	if !on_cooldown:
		$Sprite.frame_coords.x = 1
		emit_signal("on_activate")

remote func disable_remote():
	if !on_cooldown and !one_shot:
		$Sprite.frame_coords.x = 0
		emit_signal("on_deactivate")

remote func remote_cooldown_timeout():
	on_cooldown = false

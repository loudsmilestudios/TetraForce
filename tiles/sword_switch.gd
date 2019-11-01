extends Node2D

signal on_activate
signal on_deactivate

export(bool) var one_shot: bool = false

var activated: bool = false
var on_cooldown: bool = false

func _ready():
	pass

func _physics_process(delta):
	pass

func _on_HitBox_area_entered(area: Area2D):
	var sprite = $Sprite
	
	if one_shot:
		if !activated:
			activated = true
			emit_signal("on_activate")
			update_remote("enable_remote")
			
	else:
		
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
		rset_id(peer, "on_cooldown", false)

func update_remote(function: String):
	for peer in network.map_peers:
		rpc_id(peer, function)

remote func enable_remote():
	if !on_cooldown:
		$Sprite.frame_coords.x = 1
		emit_signal("on_deactivate")

remote func disable_remote():
	if !on_cooldown and !one_shot:
		$Sprite.frame_coords.x = 0
		emit_signal("on_deactivate")

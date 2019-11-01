extends Node2D

signal on_activate
signal on_deactivate

export(bool) var one_shot: bool = false

var activated: bool = false
var on_cooldown: bool = false

func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_HitBox_area_entered(area):
	var sprite = $Sprite
	
	if one_shot:
		if !activated:
			activated = true
			emit_signal("on_activate")
	else:
		
		if !on_cooldown:
			activated = !activated
			
			if (activated):
				sprite.frame_coords.x = 1
				emit_signal("on_activate")
			else:
				sprite.frame_coords.x = 0
				emit_signal("on_deactivate")
			
			$CooldownTimer.start()
			on_cooldown = true

func _on_CooldownTimer_timeout():
	on_cooldown = false

extends Switch

var _is_on = true

func _ready():
	z_index = -10

func _physics_process(delta):
	
	if $CooldownTimer.is_stopped():
		for area in $HitBox.get_overlapping_areas():
			if area.name != "Hitbox":
				continue
			var body = area.get_parent()
		
			if !body.get_groups().has("entity") && !body.get_groups().has("item"):
				continue
			if  body.get("DAMAGE") > 0 :
				$CooldownTimer.start()
				print("hit the switch!")
				
				if _is_on:
					rpc("turn_off_switch")
					turn_off_switch()
				else:
					rpc("turn_on_switch")
					turn_on_switch()
				
func turn_off_switch():
	_is_on = false
	$Sprite.frame_coords.x = 1
	
func turn_on_switch():
	_is_on = true
	$Sprite.frame_coords.x = 0

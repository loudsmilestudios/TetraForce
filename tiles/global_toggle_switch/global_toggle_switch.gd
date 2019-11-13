extends Switch

func _ready():
	z_index = -10
	network.connect("on_switch_toggled", self, "_toggle_switch")

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
				
				network.toggle_global_switch()
				
func _toggle_switch():
	if network.toggle_block_state:
		$Sprite.frame_coords.x = 0
	else:
		$Sprite.frame_coords.x = 1

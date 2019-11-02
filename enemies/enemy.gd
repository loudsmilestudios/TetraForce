extends Entity

class_name Enemy

func _ready():
	add_to_group("enemy")
	set_collision_layer_bit(0,0)
	set_collision_mask_bit(0,0)
	set_collision_layer_bit(1,1)
	set_collision_mask_bit(1,1)
	
	connect("hitstun_end", self, "check_for_death")

func check_for_death():
	print("checking for death ", health)
	if health == 0:
		rpc("enemy_death")

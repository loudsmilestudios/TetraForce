extends Enemy

func _ready() -> void:
	puppet_pos = position
	puppet_spritedir = spritedir
	movedir = entity_helper.rand_direction()

func _physics_process(delta:float) -> void:
	if !is_scene_owner() || is_dead():
		return
	
	loop_movement()
	loop_damage()
	
	var target_position = get_tree().get_nodes_in_group("player")[0].position
	if position.distance_to(target_position) < 64:
		movedir = (target_position - position).normalized()
		

func puppet_update() -> void:
	position = puppet_pos
	
func _process(delta: float) -> void:
	loop_network()

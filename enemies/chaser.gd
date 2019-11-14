extends Enemy

var target_timer_length = 50
var target_timer = 0

func _ready() -> void:
	puppet_pos = position
	puppet_spritedir = spritedir

func _physics_process(delta:float) -> void:
	if !is_scene_owner() || is_dead():
		return
	
	loop_movement()
	loop_damage()
	
	
	var closest_player = get_tree().get_nodes_in_group("player")[0]
	var closest_players = get_tree().get_nodes_in_group("player")
	var distance_from_closest = position.distance_to(closest_player.position)
	var chasing = false 
	
	if target_timer > 0:
		target_timer -= 1
	
		
	if target_timer == 0:
		
		for player in closest_players:
			if position.distance_to(player.position) < distance_from_closest:
				closest_player = player
				
			if position.distance_to(closest_player.position) < 64:
				movedir = (closest_player.position - position).normalized()
				
			if position.distance_to(closest_player.position) > 72:
				movedir = Vector2(0,0)
				target_timer = target_timer_length
		
		

func puppet_update() -> void:
	position = puppet_pos
	
func _process(delta: float) -> void:
	loop_network()

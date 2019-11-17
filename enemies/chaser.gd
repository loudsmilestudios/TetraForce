extends Enemy

var target_timer_length = 50
var target_timer = 0
var movetimer_length = 60
var movetimer = 0


func _ready() -> void:
	puppet_pos = position
	puppet_spritedir = spritedir
	puppet_anim = "idleDown"

func _physics_process(delta:float) -> void:
	if !is_scene_owner() || is_dead():
		return
	loop_movement()
	loop_damage()
	loop_spritedir()
	
	var closest_player = get_tree().get_nodes_in_group("player")[0]
	var closest_players = get_tree().get_nodes_in_group("player")
	var distance_from_closest = position.distance_to(closest_player.position)
	
	
	if movetimer > 0:
		movetimer -= 1
		anim_switch("walk")
	if (movetimer == 0 || is_on_wall()) && hitstun == 0:
		movedir = entity_helper.rand_direction()
		movetimer = movetimer_length
		anim_switch("walk")
	if target_timer > 0:
		target_timer -= 1
	if target_timer == 0:
		for player in closest_players:
			if position.distance_to(player.position) < distance_from_closest:
					closest_player = player
					distance_from_closest = position.distance_to(closest_player.position)
	
	if distance_from_closest < 64:
		movedir = (closest_player.position - position).normalized()
		match movedir.round():
			Vector2.LEFT:
				spritedir = "Left"
				#anim_switch("walk")
				puppet_spritedir = spritedir
			Vector2.RIGHT:
				spritedir = "Right"
				#anim_switch("walk")
				puppet_spritedir = spritedir
			Vector2.UP:
				spritedir = "Up"
				#anim_switch("walk")
				puppet_spritedir = spritedir
			Vector2.DOWN:
				spritedir = "Down"
				#anim_switch("walk")
				puppet_spritedir = spritedir

func puppet_update() -> void:
	position = puppet_pos
	spritedir = puppet_spritedir
	if anim.current_animation != puppet_anim:
		anim.play(puppet_anim)
	sprite.flip_h = (spritedir == "Left")
	
func _process(delta: float) -> void:
	loop_network()

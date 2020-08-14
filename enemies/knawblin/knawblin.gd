extends Enemy

var movetimer_length = 15
var movetimer = 0

func _ready():
	movedir = rand_direction()

func _physics_process(delta):
	if !network.is_map_host() || is_dead():
		return
	
	if !is_network_master():
		sprite.flip_h = (spritedir == "Left")
		return
	
	loop_movement()
	loop_damage()
	loop_spritedir()
	
	anim_switch("walk")
	
	if movetimer > 0:
		movetimer -= 1
	if movetimer == 0 || is_on_wall():
		movedir = rand_direction()
		movetimer = movetimer_length

func throw_projectile():
	if network.is_map_host():
		var closest_player;
		for body in $Area2D.get_overlapping_bodies():
			if body is Player:
				if !closest_player: 
					closest_player = body;
				elif (body.position - closest_player.position).size() < closest_player.position:
					closest_player = body
		if !closest_player:
			return
		var dir_to_player = (closest_player.position - position).normalized()
		var direction = Vector2.ZERO
		if abs(dir_to_player.y) < abs(dir_to_player.x):
			direction.y = 0;
			if dir_to_player.x < 0:
				direction.x = -1
			else:
				direction.x = 1;
		if abs(dir_to_player.x) < abs(dir_to_player.y):
			direction.x = 0;
			if dir_to_player.y < 0:
				direction.y = -1
			else:
				direction.y = 1;
		spritedir = direction
		# Throw projectile
		use_item("res://enemy_items/javelin.tscn", direction)

func _on_Timer_timeout():
	throw_projectile()
	$Timer.start()
	pass # Replace with function body.

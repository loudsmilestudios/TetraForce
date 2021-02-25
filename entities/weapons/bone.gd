extends Weapon

const SPEED = 100
var movedir = Vector2(0,0)
var shooter
var received_sync = false

func start():
	$AnimationPlayer.play("spin")
	shooter = get_parent()
	$Hitbox.connect("body_entered", self, "body_entered")
	add_to_group("projectile")
	#z_index = shooter.z_index - 1
	position = shooter.position
	get_parent().remove_child(self)
	shooter.get_parent().add_child(self)
	
	var players = get_tree().get_nodes_in_group("player")
	var shortest_distance = 999999
	var closest_player = null
	for player in players:
		if position.distance_to(player.position) < shortest_distance:
			shortest_distance = position.distance_to(player.position)
			closest_player = player
	movedir = Vector2(-1,0).rotated(position.angle_to_point(closest_player.position))
	
	set_physics_process(true)

func _physics_process(delta):
	position += movedir * SPEED * delta

func body_entered(body):
	if !received_sync && !is_network_master() && body != shooter:
		queue_free()
	elif body.get_collision_layer_bit(7) == true:
		return
	elif body is Entity && body != shooter:
		damage(body)
	elif body != shooter:
		delete()
		network.peer_call(self, "delete")

extends Enemy

onready var detect = $PlayerDetect

var received_sync = false
var active = false

func _ready():
	add_to_group("invunerable")
	
func _physics_process(delta):
	position += movedir * SPEED * delta
	var sees_player = false
	if !network.is_map_host() || is_dead():
		return
	for body in detect.get_overlapping_bodies():
		if body is Player || is_dead():
			sees_player = true
			if active != true:
				if network.is_map_host():
					launch()
				else:
					network.peer_call(self, "launch")
			
	loop_movement()
	loop_damage()
	
func launch():
	active = true
	$AnimationPlayer.play("lift")
	network.peer_call($AnimationPlayer, "play", ["lift"])
	yield(get_tree().create_timer(5), "timeout")
	$AnimationPlayer.play("launch")
	network.peer_call($AnimationPlayer, "play", ["launch"])
	if is_in_group("invunerable"):
				remove_from_group("invunerable")
				$Hitbox.connect("body_entered", self, "body_entered")
					
	var players = get_tree().get_nodes_in_group("player")
	var shortest_distance = 999999
	var closest_player = null
	for player in players:
		if position.distance_to(player.position) < shortest_distance:
			shortest_distance = position.distance_to(player.position)
			closest_player = player
	movedir = Vector2(-1,0).rotated(position.angle_to_point(closest_player.position))
	
func body_entered(body):
	movedir = Vector2(0,0)
	yield(get_tree().create_timer(0.01), "timeout")
	add_to_group("invunerable")
	if !received_sync && !is_network_master():
		$AnimationPlayer.play("explode")
		network.peer_call($AnimationPlayer, "play", ["explode"])
		sfx.play("boom")
		yield(get_tree().create_timer(0.55), "timeout")
		queue_free()
		network.peer_call(self, "queue_free")
	elif body.get_collision_layer_bit(7) == true:
		return
	elif body is Entity && body:
		$AnimationPlayer.play("explode")
		network.peer_call($AnimationPlayer, "play", ["explode"])
		sfx.play("boom")
		yield(get_tree().create_timer(0.55), "timeout")
		queue_free()
		network.peer_call(self, "queue_free")
	else:
		$AnimationPlayer.play("explode")
		network.peer_call($AnimationPlayer, "play", ["explode"])
		sfx.play("boom")
		yield(get_tree().create_timer(0.55), "timeout")
		queue_free()
		network.peer_call(self, "queue_free")
	

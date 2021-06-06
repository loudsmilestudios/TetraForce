extends Enemy

onready var detect = $PlayerDetect

var received_sync = false
var active = false

func _ready():
	add_to_group("invunerable")
	$Hitbox.connect("body_entered", self, "body_entered")
	
func _physics_process(delta):
	position += movedir * SPEED * delta
	var sees_player = false
	if !network.is_map_host() || is_dead():
		return
	for body in detect.get_overlapping_bodies():
		if body is Player:
			sees_player = true
			if active != true:
				launch()
			
	loop_movement()
	loop_damage()
	
func launch():
	active = true
	$AnimationPlayer.play("lift")
	yield(get_tree().create_timer(5), "timeout")
	$AnimationPlayer.play("launch")
	if is_in_group("invunerable"):
				remove_from_group("invunerable")
	
	var players = get_tree().get_nodes_in_group("player")
	var shortest_distance = 999999
	var closest_player = null
	for player in players:
		if position.distance_to(player.position) < shortest_distance:
			shortest_distance = position.distance_to(player.position)
			closest_player = player
	movedir = Vector2(-1,0).rotated(position.angle_to_point(closest_player.position))
	$Tween.interpolate_property($Sprite,"position:y",-16,0,0.5, Tween.TRANS_LINEAR)
	$Tween.start()
	
func body_entered(body):
	movedir = Vector2(0,0)
	add_to_group("invunerable")
	if !received_sync && !is_network_master():
		$AnimationPlayer.play("explode")
		yield(get_tree().create_timer(0.55), "timeout")
		queue_free()
	elif body.get_collision_layer_bit(7) == true:
		return
	elif body is Entity && body:
		$AnimationPlayer.play("explode")
		yield(get_tree().create_timer(0.55), "timeout")
		queue_free()
	else:
		$AnimationPlayer.play("explode")
		yield(get_tree().create_timer(0.55), "timeout")
		queue_free()
		network.peer_call(self, "queue_free")
	

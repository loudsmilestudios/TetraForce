extends Enemy

var movetimer_length = 30
var movetimer = 0

onready var detect = $PlayerDetect

func _ready():
	MAX_HEALTH = 0.5
	DAMAGE = 0.5
	health = MAX_HEALTH
	movedir = rand_direction()
	SPEED = 50

func _physics_process(delta):
	if !network.is_map_host() || is_dead():
		return
	
	var sees_player = false
	if !network.is_map_host() || is_dead():
		return
	for body in detect.get_overlapping_bodies():
		if body is Player:
			sees_player = true
	
	loop_movement()
	loop_spritedir()
	loop_damage()
	loop_holes()
	
	anim_switch("walk")
	
	if movetimer > 0:
		movetimer -= 1

	if movetimer == 10:
		movedir = Vector2.ZERO

	if movetimer == 0 || is_on_wall():
		movetimer = movetimer_length
		movedir = rand_direction()
		if movedir == Vector2.UP:
			$PlayerDetect/CollisionPolygon2D.rotation_degrees = 0.0
		if movedir == Vector2.DOWN:
			$PlayerDetect/CollisionPolygon2D.rotation_degrees = 180.0
		if movedir == Vector2.RIGHT:
			$PlayerDetect/CollisionPolygon2D.rotation_degrees = 90.0
		if movedir == Vector2.LEFT:
			$PlayerDetect/CollisionPolygon2D.rotation_degrees = 270.0
		var players = get_tree().get_nodes_in_group("player")
		var shortest_distance = 999999
		var closest_player = null
		for player in players:
			if position.distance_to(player.position) < shortest_distance:
				shortest_distance = position.distance_to(player.position)
				closest_player = player
		for body in detect.get_overlapping_bodies():
			if body == closest_player && closest_player != null:
				movedir = Vector2(-1,0).rotated(position.angle_to_point(closest_player.position))
				$PlayerDetect/CollisionPolygon2D.rotation_degrees = rad2deg(position.angle_to_point(closest_player.position)) + 270
				movetimer = 120
		movetimer = movetimer_length

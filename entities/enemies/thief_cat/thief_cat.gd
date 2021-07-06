extends Enemy

var movetimer_length = 50
var movetimer = 0
var new_rotation
var sees_player = false

var hold = false setget set_hold

onready var detect = $PlayerDetect
onready var enemy_array = $PlayerDetect/CollisionPolygon2D


func _ready():
	MAX_HEALTH = 1
	DAMAGE = 0.5
	health = MAX_HEALTH
	movedir = rand_direction()
	SPEED = 35

func _physics_process(delta):
	if !network.is_map_host() || is_dead():
		sprite.flip_h = (spritedir == "Left")
		return
		
	for body in detect.get_overlapping_bodies():
		if body is Player:
			sees_player = true
			SPEED = 50
			movetimer = 120
		else:
			if movetimer == 0 || is_on_wall():
				movetimer = movetimer_length
				movedir = rand_direction_fair(movedir)
			sees_player = false
			SPEED = 20
	if sees_player == false:
		set_hold(false)
	
	loop_spritedir()
	loop_movement()
	loop_damage()
	loop_holes()
	set_direction()
	
	if movedir != Vector2.ZERO:
		anim_switch("walk")
	else:
		anim_switch("idle")
	
	if movetimer > 0:
		movetimer -= 1
		
	for body in get_slide_count():
		var collision = get_slide_collision(body)
		if collision.collider is TileMap:
			set_hold(true)
		
	var players = get_tree().get_nodes_in_group("player")
	var shortest_distance = 999999
	var closest_player = null
	for player in players:
		if position.distance_to(player.position) < shortest_distance:
			shortest_distance = position.distance_to(player.position)
			closest_player = player
	for body in detect.get_overlapping_bodies():
		if body == closest_player && closest_player != null:
			if hold == false:
				movedir = Vector2(-1,0).rotated(position.angle_to_point(closest_player.position))
			else:
				movedir = Vector2.ZERO
				
			enemy_array.rotation_degrees = rad2deg(position.angle_to_point(closest_player.position)) + 270
			
			new_rotation = int(enemy_array.rotation_degrees)
			
			if new_rotation >= 251 and new_rotation <= 290:
				spritedir = "Left"
			if new_rotation >= 71 and new_rotation <= 110:
				spritedir = "Right"
			if new_rotation >= 0 and new_rotation <= 70 or new_rotation >= 291 and new_rotation <= 360:
				spritedir = "Up"
			if new_rotation >= 111 and new_rotation <= 250:
				spritedir = "Down"
			
func set_direction():
	match movedir:
		Vector2.LEFT:
			enemy_array.rotation_degrees = 270.0
		Vector2.RIGHT:
			enemy_array.rotation_degrees = 90.0
		Vector2.UP:
			enemy_array.rotation_degrees = 0.0
		Vector2.DOWN:
			enemy_array.rotation_degrees = 180.0
			
func set_hold(value):
	hold = value

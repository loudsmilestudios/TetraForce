extends Enemy

var movetimer_length = 70
var movetimer = 0
var active = false

onready var detect = $PlayerDetect

func _ready():
	MAX_HEALTH = 0.5
	DAMAGE = 0.5
	health = MAX_HEALTH
	SPEED = 30

func _physics_process(delta):
	position += movedir * SPEED * delta
	var sees_player = false
		
	if !network.is_map_host() || is_dead():
		return
	for body in detect.get_overlapping_bodies():
		if body is Player:
			sees_player = true
			if !anim.is_playing() && anim.assigned_animation != "activate":
				anim.play("activate")
				network.peer_call(anim, "play", ["activate"])
				if movetimer == 0:
						movetimer = movetimer_length
			if movetimer > 0:
				pursue_player()

	if movetimer <= 0 && !sees_player:
		movedir = Vector2.ZERO
		if anim.current_animation == "sees_player":
			anim.play("land")
			network.peer_call(anim, "play", ["land"])
			yield(get_tree().create_timer(5), "timeout")
	
	if anim.current_animation == "activate":
		return
	
	if anim.current_animation != "sees_player" && movetimer > 0:
		anim.play("sees_player")
		network.peer_call(anim, "play", ["sees_player"])

	loop_movement()
	loop_damage()
	
	if movetimer > 0:
		movetimer -= 1
	
func pursue_player():
	if movetimer > 0 || is_on_wall():
		var players = get_tree().get_nodes_in_group("player")
		var shortest_distance = 999999
		var closest_player = null
		for player in players:
			if position.distance_to(player.position) < shortest_distance:
				shortest_distance = position.distance_to(player.position)
				closest_player = player
		movedir = Vector2(-1,0).rotated(position.angle_to_point(closest_player.position))

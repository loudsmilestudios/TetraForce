extends Enemy

var movetimer_length = 150
var movetimer = 0
var sees_player = false

onready var detect = $PlayerDetect
onready var bombed = false setget set_bombed

func _ready():
	movedir = rand_direction()
	MAX_HEALTH = 2
	DAMAGE = 0.5
	health = MAX_HEALTH
	SPEED = 10

func _physics_process(delta):
	if !network.is_map_host() || is_dead():
		sprite.flip_h = (spritedir == "Left")
		return
	
	for body in detect.get_overlapping_bodies():
		if body is Player:
			sees_player = true
			if !is_in_group("invunerable"):
				add_to_group("invunerable")
				add_to_group("bombable")
		else:
			sees_player = false
			if is_in_group("invunerable"):
				remove_from_group("invunerable")
	
	if sees_player:
		anim.play("shell")
		movedir = Vector2.ZERO
		movetimer = 0
		if !is_in_group("invunerable"):
			add_to_group("invunerable")
	else:
		loop_movement()
		loop_damage()
		anim_switch("walk")
		
		if movedir == Vector2.ZERO:
			anim_switch("idle")
	
		if movetimer > 0:
			movetimer -= 1
		
		if movetimer == 0 || is_on_wall() && hitstun == 0:
			movedir = rand_direction()
			movetimer = movetimer_length
	
		if movetimer == 50:
			movedir = Vector2.ZERO
			use_weapon("Rock")
			network.peer_call(self, "use_weapon", ["Rock"])
			
	loop_spritedir()
	loop_holes()

func bombed(show_animation=true):
	$CollisionShape2D.queue_free()
	bombed = true
	if show_animation:
		var animation = preload("res://effects/bombable_rock_explosion.tscn").instance()
		get_parent().add_child(animation)
		animation.position = position
	yield(get_tree(), "idle_frame")
	set_dead()

func set_bombed(b):
	if b:
		bombed(false)
	
	

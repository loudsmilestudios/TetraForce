extends Enemy

var movetimer_length = 150
var movetimer = 0
var sees_player = false
var shell = false

onready var detect = $PlayerDetect
onready var bombed = false setget set_bombed

func _ready():
	movedir = rand_direction()
	MAX_HEALTH = 2
	DAMAGE = 0.5
	health = MAX_HEALTH
	SPEED = 10

func contains_player(bodies):
	for body in bodies:
		if body is Player:
			return true
	return false

func _physics_process(delta):
	if !network.is_map_host() || is_dead():
		sprite.flip_h = (spritedir == "Left")
		return
	
	sees_player = contains_player(detect.get_overlapping_bodies())
	
	if sees_player:
		if !"shell" in anim.current_animation && !anim.current_animation == "":
			anim_switch("shell")
			network.peer_call(self, "anim_switch", ["shell"])
		shell = true
		movedir = Vector2.ZERO
		movetimer = 0
		if !is_in_group("invunerable"):
			add_to_group("invunerable")
			add_to_group("bombable")
	else:
		loop_damage()
		anim_switch("walk")
		network.peer_call(self, "anim_switch", ["walk"])
		shell = false
		if is_in_group("invunerable"):
			remove_from_group("invunerable")

		if movetimer > 0:
			movetimer -= 1
		
		if movetimer == 0 || is_on_wall() && hitstun == 0:
			movedir = rand_direction()
			movetimer = movetimer_length
	
		if movetimer == 50:
			movedir = Vector2.ZERO
			use_weapon("Spike")
			network.peer_call(self, "use_weapon", ["Spike"])
			
	loop_movement()
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
	
	

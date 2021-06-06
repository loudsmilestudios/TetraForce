extends Enemy

var movetimer_length = 15
var movetimer = 0
var bonetimer_length = 50
var bonetimer = 0
onready var detect = $PlayerDetect

func _ready():
	anim.play("unanimate")
	add_to_group("invunerable")
	movedir = rand_direction()

func _physics_process(delta):
	var sees_player = false
	if !network.is_map_host() || is_dead():
		return
	for body in detect.get_overlapping_bodies():
		if body is Player:
			sees_player = true
			if !anim.is_playing() && anim.assigned_animation != "animate":
				bonetimer = bonetimer_length
				anim.play("animate")
				network.peer_call(anim, "play", ["animate"])
				remove_from_group("invunerable")
	if !sees_player:
		if anim.current_animation == "walk":
			anim.play("unanimate")
			network.peer_call(anim, "play", ["unanimate"])
		if anim.current_animation == "throw":
			anim.play("unanimate")
			network.peer_call(anim, "play", ["unanimate"])
		add_to_group("invunerable")
		return
	if anim.current_animation == "animate":
		return
	if anim.current_animation != "walk" && bonetimer > 0:
		anim.play("walk")
		network.peer_call(anim, "play", ["walk"])
		if is_in_group("invunerable"):
			remove_from_group("invunerable")
	
	loop_movement()
	loop_damage()
	loop_holes()
	
	if movetimer > 0:
		movetimer -= 1
	if movetimer == 0 || is_on_wall():
		movedir = rand_direction()
		movetimer = movetimer_length
	
	if bonetimer > 0:
		bonetimer -= 1
	if bonetimer <= 0:
		anim.play("throw")
		network.peer_call(anim, "play", ["throw"])
		
	animation = anim.current_animation

func throw():
		use_weapon("Bone")
		network.peer_call(self, "use_weapon", ["Bone"])
		bonetimer = bonetimer_length * rand_range(4, 5.5)
		return

extends Enemy

var movetimer_length = 15
var movetimer = 0

func _ready():
	anim.play("default")
	movedir = rand_direction()

func _physics_process(delta):
	if !network.is_map_host() || is_dead():
		return
	
	loop_movement()
	loop_damage()
	
	if movetimer > 0:
		movetimer -= 1
	if movetimer == 0 || is_on_wall():
		movedir = rand_direction()
		movetimer = movetimer_length

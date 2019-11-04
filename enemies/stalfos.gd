extends Enemy

var movetimer_length = 15
var movetimer = 0

func _ready():
	puppet_pos = position
	
	anim.play("default")
	movedir = entity_helper.rand_direction()

func _physics_process(delta):
	if !is_scene_owner() || is_dead():
		return
	
	loop_movement()
	loop_damage()
	
	if movetimer > 0:
		movetimer -= 1
	if movetimer == 0 || is_on_wall():
		movedir = entity_helper.rand_direction()
		movetimer = movetimer_length

func puppet_update():
	position = puppet_pos

func _process(delta):
	loop_network()

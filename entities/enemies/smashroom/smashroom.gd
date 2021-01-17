extends Enemy

var movetimer_length = 15
var movetimer = 0

func _ready():
	connect("damaged", self, "knockback_back")
	anim.play("default")
	movedir = rand_direction()

func _physics_process(delta):
	if !network.is_map_host() || is_dead():
		return
	
	loop_movement()
	loop_damage()
	loop_holes()
	
	if movetimer > 0:
		movetimer -= 1
	if movetimer == 0 || is_on_wall():
		movedir = rand_direction()
		movetimer = movetimer_length

func knockback_back(body):
	if body.get_parent() is Entity && !body.is_in_group("projectile"):
		body.get_parent().damage(0, -knockdir, self)

extends Enemy

var movetimer_length: int = 100
var movetimer: int = 0

func _ready():
	anim.play("idleDown")
	movedir = rand_direction()

func _physics_process(delta):
	if !network.is_map_host() || is_dead():
		return
	
	loop_movement()
	loop_damage()
	loop_spritedir()
	
	if movetimer > 50:
		anim_switch("walk")
	else:
		movedir = Vector2.ZERO
		anim_switch("idle")
	
	if movetimer > 0:
		movetimer -= 1
	if (movetimer == 0 || is_on_wall()) && hitstun == 0:
		movedir = rand_direction()
		movetimer = movetimer_length
	
	if movetimer == 25:
		use_weapon("Bow")
		network.peer_call(self, "use_weapon", ["Bow"])

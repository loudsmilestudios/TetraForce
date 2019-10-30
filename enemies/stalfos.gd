extends Entity

var movetimer_length = 15
var movetimer = 0

puppet var puppet_pos = position

func _ready():
	anim.play("default")
	movedir = rand_direction()
	connect("update_position", self, "_on_update_position")

func _physics_process(delta):
	if !is_scene_owner():
		return
	
	loop_movement()
	loop_damage()
	
	if movetimer > 0:
		movetimer -= 1
	if movetimer == 0 || is_on_wall():
		movedir = rand_direction()
		movetimer = movetimer_length

func _on_update_position(value):
	rset_map("puppet_pos", value)

func puppet_update():
	position = puppet_pos

func _process(delta):
	loop_network()

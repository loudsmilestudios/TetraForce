extends Entity

var movetimer_length = 15
var movetimer = 0

puppet var puppet_pos = position

func _ready():
	anim.play("default")
	movedir = rand_direction()

func _physics_process(delta):
	set_network_master(network.map_owners[network.current_map.name])
	if !network.map_owners[network.current_map.name] == get_tree().get_network_unique_id():
		return
	
	loop_movement()
	loop_damage()
	
	if movetimer > 0:
		movetimer -= 1
	if movetimer == 0 || is_on_wall():
		movedir = rand_direction()
		movetimer = movetimer_length
	
	rset_map("puppet_pos", position)

func _process(delta):
	if !network.map_owners[network.current_map.name] == get_tree().get_network_unique_id():
		position = puppet_pos
	if position == Vector2(0,0):
		hide()
	else:
		show()

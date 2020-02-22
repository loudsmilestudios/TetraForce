extends Enemy

var movetimer_length: int = 100
var movetimer: int = 0

func _ready() -> void:
	puppet_pos = position
	puppet_spritedir = spritedir
	puppet_anim = "idleDown"
	
	movedir = entity_helper.rand_direction()

func _physics_process(delta: float) -> void:
	if !is_scene_owner() || is_dead():
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
		movedir = entity_helper.rand_direction()
		movetimer = movetimer_length
	
	if movetimer == 25:
		use_item("res://items/arrow.tscn", "A")
		for peer in network.map_peers:
			rpc_id(peer, "use_item", "res://items/arrow.tscn", "A")

func puppet_update() -> void:
	position = puppet_pos
	spritedir = puppet_spritedir
	if anim.current_animation != puppet_anim:
		anim.play(puppet_anim)
	sprite.flip_h = (spritedir == "Left")

func _process(delta: float) -> void:
	loop_network()

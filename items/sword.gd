extends Item

onready var anim = $AnimationPlayer

func start():
	if get_parent().is_network_master():
		anim.connect("animation_finished", self, "destroy")
		if get_parent().has_method("state_swing"):
			get_parent().state = "swing"
	anim.play(str("swing", get_parent().spritedir))
	sfx.play(load(str("res://items/sword_swing",int(rand_range(1,5)),".wav")))

func destroy(animation):
	if input != null && Input.is_action_pressed(input):
		set_physics_process(true)
		match get_parent().spritedir:
			"Left":
				position.x += 3
			"Right":
				position.x -= 3
			"Up":
				position.y += 4
				z_index -= 1
			"Down":
				position.y -= 3
		for peer in network.map_peers:
			rpc_id(peer, "set_pos", position)
		return
	
	for peer in network.map_peers:
		rpc_id(peer, "delete")
	delete()

remote func set_pos(p_pos):
	position = p_pos

sync func delete():
	get_parent().state = "default"
	get_parent().spinAtk = false
	queue_free()

func _physics_process(delta):
	if get_parent().has_method("state_hold") and get_parent().state != "spin":
		get_parent().state = "hold"
		if get_parent().holdTimer.is_stopped() and !get_parent().spinAtk:
			get_parent().holdTimer.start()
	if !Input.is_action_pressed(input):
		
		# Spin attack
		if get_parent().has_method("state_spin") and get_parent().spinAtk and get_parent().state != "spin":
			get_parent().state = "spin"
			anim.play("spin")
			match get_parent().spritedir:
				"Left":
					anim.advance(0.2)
				"Right":
					anim.advance(0.2)
					scale.x = -1
				"Up":
					anim.advance(0.08)
				"Down":
					anim.advance(0.3)
			get_parent().anim.connect("animation_finished", self, "destroy")
			get_parent().anim.connect("animation_changed", self, "destroy")
			sfx.play(load(str("res://items/sword_swing",int(rand_range(1,5)),".wav"))) # get beter sfx
		else:
			if get_parent().get("holdTimer"):
				get_parent().holdTimer.stop()
				if not get_parent().spinAtk:
					destroy(null)
			else:
				destroy(null)

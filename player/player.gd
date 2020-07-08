extends Entity

func initialize():
	add_to_group("player")
	if is_network_master():
		set_physics_process(false)
		state = "default"
		puppet_pos = position
		puppet_spritedir = "Down"
		puppet_anim = "idleDown"
		
		position = get_parent().get_node(global.next_entrance).position
		var offset = get_parent().get_node(global.next_entrance).player_position
		match offset:
			"up":
				position.y -= 16
				spritedir = "Up"
			"down":
				position.y += 16
				spritedir = "Down"
			"left":
				position.x -= 16
				spritedir = "Left"
			"right":
				position.x += 16
				spritedir = "Right"
		
		connect_camera()
		camera.initialize(self)
		
		anim_switch("idle")
		
		yield(screenfx, "animation_finished")
		
		set_physics_process(true)

func _physics_process(_delta):
	if !is_network_master():
		position = puppet_pos
		spritedir = puppet_spritedir
		if anim.current_animation != puppet_anim:
			anim.play(puppet_anim)
		sprite.flip_h = (spritedir == "Left")
		return
		
	match state:
		"default":
			state_default()
		"swing":
			state_swing()
		"hold":
			state_hold()
		"spin":
			state_spin()

func state_default():
	loop_controls()
	loop_movement()
	loop_spritedir()
	loop_action_button()
	
	if movedir == Vector2.ZERO:
		anim_switch("idle")
	else:
		anim_switch("walk")

func state_swing():
	anim_switch("swing")
	loop_movement()
	movedir = Vector2.ZERO

func state_hold():
	loop_controls()
	loop_movement()
	if movedir == Vector2.ZERO:
		anim_switch("idle")
	else:
		anim_switch("walk")
	
	if !has_node("Sword"):
		state = "default"

func state_spin():
	anim_switch("spin")
	loop_movement()
	movedir = Vector2.ZERO

func loop_controls():
	movedir = Vector2.ZERO
	
	var LEFT = Input.is_action_pressed("LEFT")
	var RIGHT = Input.is_action_pressed("RIGHT")
	var UP = Input.is_action_pressed("UP")
	var DOWN = Input.is_action_pressed("DOWN")
	
	movedir.x = -int(LEFT) + int(RIGHT)
	movedir.y = -int(UP) + int(DOWN)

func loop_action_button():
	if Input.is_action_pressed("B"):
		use_item("res://items/sword.tscn", "B")
		for peer in network.map_peers:
			rpc_id(peer, "use_item", "res://items/sword.tscn", "B")

func connect_camera():
	camera.connect("screen_change_started", self, "screen_change_started")
	camera.connect("screen_change_completed", self, "screen_change_completed")

func screen_change_started():
	set_physics_process(false)

func screen_change_completed():
	set_physics_process(true)

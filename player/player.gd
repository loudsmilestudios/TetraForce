extends Entity

func initialize():
	add_to_group("player")
	if is_network_master():
		set_physics_process(false)
		state = "default"
		
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
				sprite.flip_h = true
			"right":
				position.x += 16
				spritedir = "Right"
		
		connect_camera()
		camera.initialize(self)
		
		anim_switch("idle")
		
		yield(screenfx, "animation_finished")
		
		set_physics_process(true)
	network.current_map.emit_signal("player_entered", int(name))

func _physics_process(_delta):
	if !is_network_master():
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
	
	network.peer_call_unreliable(self, "_player_puppet_sync", [position, spritedir, anim.current_animation])

func state_default():
	loop_controls()
	loop_movement()
	loop_spritedir()
	loop_damage()
	loop_action_button()
	
	if movedir == Vector2.ZERO:
		anim_switch("idle")
	else:
		anim_switch("walk")

func state_swing():
	anim_switch("swing")
	loop_movement()
	loop_damage()
	movedir = Vector2.ZERO

func state_hold():
	loop_controls()
	loop_movement()
	loop_damage()
	if movedir == Vector2.ZERO:
		anim_switch("idle")
	else:
		anim_switch("walk")
	
	if !has_node("Sword"):
		state = "default"

func state_spin():
	anim_switch("spin")
	loop_movement()
	loop_damage()
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
		network.peer_call(self, "use_item", ["res://items/sword.tscn", "B"])

func connect_camera():
	camera.connect("screen_change_started", self, "screen_change_started")
	camera.connect("screen_change_completed", self, "screen_change_completed")

func _player_puppet_sync(pos, sdir, animation):
	position = pos
	spritedir = sdir
	if !anim.current_animation == animation:
		anim.play(animation)
	sprite.flip_h = (spritedir == "Left")

func screen_change_started():
	set_physics_process(false)

func screen_change_completed():
	set_physics_process(true)

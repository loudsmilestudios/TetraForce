extends Entity

onready var ray = $RayCast2D

var action_cooldown = 0

# MULTIPLAYER
puppet var puppet_pos = position
puppet var puppet_spritedir = "Down"
puppet var puppet_anim = "idleDown"

func _ready():
	add_to_group("player")
	ray.add_exception(hitbox)
	
	connect_camera()
	
	if is_network_master():
		var hud = get_parent().get_node("HUD")
		hud.player = self
		hud.initialize()

func initialize():
	if is_network_master():
		camera.initialize(self)

func _physics_process(delta):
	# puppet
	if !is_network_master():
		position = puppet_pos
		spritedir = puppet_spritedir
		sprite.texture = texture_default
		
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
		"fall":
			state_fall()
	
	if action_cooldown > 0:
		action_cooldown -= 1
	
	#if movedir.length() > 1:
	#	$Sprite.global_position = global_position.snapped(Vector2(1,1))
	
	# syncing
	rset_unreliable_map("puppet_pos", position)
	rset_unreliable_map("puppet_spritedir", spritedir)
	rset_unreliable_map("puppet_anim", anim.current_animation)

func state_default():
	loop_controls()
	loop_movement()
	loop_damage()
	loop_spritedir()
	loop_interact()
	
	if movedir.length() == 1:
		ray.cast_to = movedir * 8
	
	if movedir == Vector2.ZERO:
		anim_switch("idle")
	elif is_on_wall() && ray.is_colliding() && !ray.get_collider().is_in_group("nopush"):
		anim_switch("push")
	else:
		anim_switch("walk")
	
	if Input.is_action_just_pressed("B") && action_cooldown == 0:
		use_item("res://items/sword.tscn", "B")
		for peer in network.map_peers:
			rpc_id(peer, "use_item", "res://items/sword.tscn", "B")

func state_swing():
	anim_switch("swing")
	loop_movement()
	loop_damage()
	movedir = Vector2.ZERO

func state_hold():
	loop_controls()
	loop_movement()
	loop_damage()
	if movedir != Vector2(0,0):
		anim_switch("walk")
	else:
		anim_switch("idle")
	
	if !Input.is_action_pressed("A") && !Input.is_action_pressed("B"):
		state = "default"

func state_fall():
	anim_switch("jump")
	position.y += 100 * get_physics_process_delta_time()
	
	$CollisionShape2D.disabled = true
	var colliding = false
	for body in hitbox.get_overlapping_bodies():
		if body is TileMap:
			colliding = true
	if !colliding:
		$CollisionShape2D.disabled = false
		sfx.play(preload("res://player/player_land.wav"), 20)
		state = "default"

func loop_controls():
	movedir = Vector2.ZERO
	
	var LEFT = Input.is_action_pressed("LEFT")
	var RIGHT = Input.is_action_pressed("RIGHT")
	var UP = Input.is_action_pressed("UP")
	var DOWN = Input.is_action_pressed("DOWN")
	
	movedir.x = -int(LEFT) + int(RIGHT)
	movedir.y = -int(UP) + int(DOWN)

func loop_interact():
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.is_in_group("interact") && Input.is_action_just_pressed("A") && action_cooldown == 0:
			collider.interact(self)
		elif collider.is_in_group("cliff") && spritedir == "Down":
			position.y += 2
			sfx.play(preload("res://player/player_jump.wav"), 20)
			state = "fall"
		elif collider.is_in_group("subitem"):
			collider.collect(self)

func connect_camera():
	camera.connect("screen_change_started", self, "screen_change_started")
	camera.connect("screen_change_completed", self, "screen_change_completed")

func screen_change_started():
	set_physics_process(false)

func screen_change_completed():
	set_physics_process(true)

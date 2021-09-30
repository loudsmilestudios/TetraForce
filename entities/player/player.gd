extends Entity

class_name Player

onready var nametag = $name/nametag
onready var ray = $RayCast2D
onready var collision = $CollisionShape2D
var hud

var push_counter = 0
var action_cooldown = 0
var screen_position = Vector2(0,0)
var last_safe_spritedir = "Down"
var current_zone

var drowning = false

func initialize():
	hurt_sfx = "hurt"
	add_to_group("player")
	if is_network_master():
		global.player = self
		set_physics_process(false)
		state = "default"
		health = global.health
		MAX_HEALTH = global.max_health
		
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
			
		home_position = position
		ray.set_collision_mask_bit(6, 1)
		
		if global.transition_type == true:
			anim.play("dropDown")
			global.transition_type = false
			spritedir = "Down"
		else:
			anim_switch("idle")
		
		camera.initialize(self)
		
		
		hud = preload("res://ui/hud/hud.tscn").instance()
		add_child(hud)
		hud.initialize(self)
		connect("update_count", hud, "update_weapons")
		nametag.hide()
		
		#$ZoneHandler.connect("area_entered", self, "zone_changed")
		ray.add_exception($ZoneHandler)
		ray.add_exception(hitbox)
		ray.add_exception(center)
		
		$ZoneHandler.connect("area_entered", self, "change_zone")
		yield(get_tree(), "idle_frame")
		camera.get_node("Tween").remove_all()
		yield(get_tree(), "idle_frame")
		var zone = $ZoneHandler.get_overlapping_areas()[0]
		var zone_size = zone.get_node("CollisionShape2D").shape.extents * 2
		var zone_rect = Rect2(zone.position, zone_size)
		current_zone = zone
		camera.set_limits(zone_rect)
		camera.smoothing_enabled = true
		yield(get_tree(), "idle_frame")
		camera.position = position
		camera.reset_smoothing()
		camera.set_process(true)
		
		set_lightdir()
		
		yield(get_tree().create_timer(0.5), "timeout")
		while anim.current_animation == "dropDown":
			yield(get_tree(), "idle_frame")
			yield(anim, "animation_finished")
			sfx.play("fall_land")
		
		set_physics_process(true)
		global.changing_map = false
	network.current_map.emit_signal("player_entered", int(name))

func _physics_process(_delta):

	if !is_network_master():
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
		"fall":
			state_fall()
		"water":
			state_water()
		"swim":
			state_swim()
		"menu":
			state_menu()
		"acquire":
			state_acquire()
		"die":
			state_die()
	
	screen_position = position - camera.position
	animation = anim.current_animation
	
	#if Rect2(Vector2(0,0), Vector2(72, 22)).has_point(screen_position) && state != "menu":
	#	hud.hide_hearts()
	#else:
	#	hud.show_hearts()
	
	#if Rect2(Vector2(192, 0), Vector2(64, 30)).has_point(screen_position) && state != "menu":
	#	hud.hide_buttons()
	#else:
	#	hud.show_buttons()
	
	set_lightdir()
	
	check_for_invunerable()
	check_for_death()
	
	if action_cooldown > 0:
		action_cooldown -= 1

func state_default():
	loop_controls()
	loop_movement()
	loop_spritedir()
	loop_damage()
	loop_action_button()
	loop_interact()
	loop_holes()
	
	if(Input.is_action_just_pressed("QUICK_SAVE")):
		global.quicksave_game_data()
	
	drowning = false
	
	if movedir.length() == 1:
		ray.cast_to = movedir * 8
	
	if movedir == Vector2.ZERO:
		anim_switch("idle")
		push_counter = 0
	elif is_on_wall() && ray.is_colliding() && !ray.get_collider().is_in_group("nopush") && movedir != Vector2.ZERO:
		anim_switch("push")
		push_counter += get_physics_process_delta_time()
	else:
		anim_switch("walk")
		push_counter = 0

func state_swing():
	anim_switch("swing")
	loop_movement()
	loop_damage()
	loop_holes()
	movedir = Vector2.ZERO

func state_hold():
	loop_controls()
	loop_movement()
	loop_damage()
	loop_holes()
	if movedir == Vector2.ZERO:
		anim_switch("idle")
		push_counter = 0
	elif is_on_wall() && ray.is_colliding():
		anim_switch("walk")
		push_counter += get_physics_process_delta_time()
	else:
		anim_switch("walk")
		push_counter = 0
	
	if !has_node("sword"):
		state = "default"

func state_spin():
	anim_switch("spin")
	loop_movement()
	loop_damage()
	movedir = Vector2.ZERO
	if hitstun != 0 || !has_node("sword"):
		state = "default"

func state_fall():
	anim_switch("jump")
	if spritedir == "Down":
		position.y += 100 * get_physics_process_delta_time()
	if spritedir == "Up":
		position.y -= 100 * get_physics_process_delta_time()
	if spritedir == "Right":
		position.x += 100 * get_physics_process_delta_time()
	if spritedir == "Left":
		position.x -= 100 * get_physics_process_delta_time()
	
	pos = position
	
	$CollisionShape2D.disabled = true
	var colliding = false
	for body in hitbox.get_overlapping_bodies():
		if body is TileMap || body is StaticBody2D:
			colliding = true
	if !colliding:
		$CollisionShape2D.disabled = false
		state = "default"
		
func state_water():
	if anim.current_animation != "fall":
		anim.play("fall")
		network.peer_call(anim, "play", ["fall"])
	if spritedir == "Down":
		position.y += 64 * get_physics_process_delta_time()
	if spritedir == "Up":
		position.y -= 64 * get_physics_process_delta_time()
	if spritedir == "Right":
		position.x += 64 * get_physics_process_delta_time()
	if spritedir == "Left":
		position.x -= 64 * get_physics_process_delta_time()
	
	pos = position
	
	yield(get_tree().create_timer(0.2), "timeout")
	for body in center.get_overlapping_bodies():
		if drowning == false:
			if body is Water:
				var water_origin = body.map_to_world(body.world_to_map(position.round() + Vector2(0,6))) + Vector2(8,8)
				var water_hitbox = Rect2(water_origin - Vector2(5,5), Vector2(10,10))
				position = position.linear_interpolate(water_origin, 0.1) # there's a way to lerp w/ delta time i forgot it tho
				position += Vector2(0, rand_range(-1,0))
				if water_hitbox.has_point(position + Vector2(0,4)):
					if spritedir == "Left":
						water_origin = (water_origin - Vector2(8,0))
					if spritedir == "Right":
						water_origin = (water_origin + Vector2(8,0))
					drowning = true
					create_drowning_fx(water_origin)
					network.peer_call(self, "create_drowning_fx", [water_origin])
					hole_fall()
					network.peer_call(self, "hole_fall")
					
func state_swim():
	state = "default"
	set_collision_layer_bit(10, 0)
	set_collision_layer_bit(6, 0)

func state_menu():
	anim_switch("idle")

func state_acquire():
	animation = "acquire"
	anim.play("acquire")
	
func check_for_invunerable():
	if invunerable >= 1 && health > 0:
		$AnimationPlayer/invunerable.play("invunerable")
		network.peer_call($AnimationPlayer/invunerable, "play", ["invunerable"])
	else: 
		$AnimationPlayer/invunerable.play("visible")
		network.peer_call($AnimationPlayer/invunerable, "play", ["visible"])
		
func state_die():
	if anim.assigned_animation != "die":
		animation = "die"
		anim.play("die")
		network.peer_call(anim, "play", ["die"])
		
func death_effect():
	var death_animation = preload("res://effects/enemy_death.tscn").instance()
	death_animation.global_position = position
	get_parent().add_child(death_animation)
	sfx.play("death")
	hide()
	$CollisionShape2D.disabled = true
	if is_network_master():
		if health <= 0:
			screenfx.play("fadeblack")
			yield(get_tree().create_timer(1.5), "timeout")
			hud.show_gameover()
			yield(get_tree().create_timer(1.5), "timeout")

func respawn():
	knockdir = Vector2(0,0)
	position = home_position
	spritedir = last_safe_spritedir
	emit_signal("health_changed")
	show()
	network.peer_call(self, "show")
	$CollisionShape2D.disabled = false
	network.peer_call(self, "reset_collision")
	network.peer_call(self, "set_hurt_texture", [false])
	state = "default"

func check_for_death():
	if health <= 0 && state != "die":
		state = "die"

func loop_controls():
	movedir = Vector2.ZERO
	
	var LEFT = Input.is_action_pressed("LEFT")
	var RIGHT = Input.is_action_pressed("RIGHT")
	var UP = Input.is_action_pressed("UP")
	var DOWN = Input.is_action_pressed("DOWN")
	
	movedir.x = -int(LEFT) + int(RIGHT)
	movedir.y = -int(UP) + int(DOWN)

func loop_action_button():
	if action_cooldown > 0:
		return
	for btn in ["B", "X", "Y"]:
		if Input.is_action_just_pressed(btn) && global.equips[btn] != "":
			var item_name = global.equips[btn]
			use_weapon(item_name, btn)
			network.peer_call(self, "use_weapon", [item_name, btn])
	if Input.is_action_just_pressed("START"):
		hud.show_inventory()
		state = "menu"
		action_cooldown = 10
	if Input.is_action_just_pressed("ESC"):
		hud.show_esc_menu()

func loop_interact():
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.is_in_group("interactable"):
			hud.show_action()
		if collider.is_in_group("interactable") && Input.is_action_just_pressed("A"):
			collider.interact(self)
		elif collider.is_in_group("cliff") && spritedir == collider.spritedir:
			state = "fall"
			sfx.play("fall2")
		elif collider.is_in_group("water"):
			if global.items.has("SeaCharm"):
				ray.set_collision_mask_bit(6, 0)
				state = "swim"
			else:
				state = "water"
		elif is_on_wall() && collider.is_in_group("pushable") && push_counter >= 0.75:
			collider.interact(self)
			push_counter = 0
	else:
		hud.hide_action()

func hole_fall():
	hide()
	for child in get_children():
		if child.is_in_group("item"):
			child.queue_free()
	state = "hole"
	yield(get_tree().create_timer(1.5), "timeout")
	position = last_safe_pos
	spritedir = last_safe_spritedir
	damage(0.5, Vector2(0,0))
	state = "default"
	show()

func set_lightdir():
	match spritedir:
		"Left":
			$Light2D.rotation_degrees = 90
		"Right":
			$Light2D.rotation_degrees = 270
		"Up":
			$Light2D.rotation_degrees = 180
		"Down":
			$Light2D.rotation_degrees = 0

func change_zone(zone):
	var zone_size = zone.get_node("CollisionShape2D").shape.extents * 2
	var zone_rect = Rect2(zone.position, zone_size)
	camera.scroll_screen(zone_rect)
	sfx.set_music(zone.music, zone.musicfx)
	camera.set_light(zone.light)
	last_safe_pos = position
	last_safe_spritedir = spritedir
	current_zone = zone

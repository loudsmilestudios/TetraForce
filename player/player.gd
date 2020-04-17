extends Entity

onready var ray: RayCast2D = $RayCast2D

var action_cooldown = 0
var push_target = null

# synced from engine/global.gd
var equip_slot: Dictionary
var items: Array

var spinAtk: bool = false
onready var holdTimer: Timer = $HoldTimer

var chat_messages: Array = [{"source": "Welcome to TetraForce!", "message": ""}]

func _ready() -> void:
	if is_network_master():
		global.player = self
		global.set_player_state()
		var hud = get_parent().get_node("HUD")
		hud.initialize()
		
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
	
	puppet_pos = position
	puppet_spritedir = "Down"
	puppet_anim = "idleDown"
	
	add_to_group("player")
	ray.add_exception(hitbox)
	
	connect_camera()
	
	$PlayerName.visible = settings.get_pref("show_name_tags")

func initialize() -> void:
	if is_network_master():
		camera.initialize(self)
		
func set_player_label(player_name: String):
	$PlayerName.text = player_name

func _physics_process(delta: float) -> void:
	# puppet
	if !is_network_master():
		position = puppet_pos
		spritedir = puppet_spritedir
		sprite.texture = texture_default
		
		if anim.current_animation != puppet_anim:
			anim.play(puppet_anim)
		
		var flip: bool = (spritedir == "Left")
		if sprite.flip_h != flip:
			sprite.flip_h = flip
		
		loop_lightdir()
		
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
		"menu":
			state_menu()
	
	if action_cooldown > 0:
		action_cooldown -= 1
	
	#if movedir.length() > 1:
	#	$Sprite.global_position = global_position.snapped(Vector2(1,1))

func state_default() -> void:
	loop_controls()
	loop_movement()
	loop_damage()
	loop_spritedir()
	loop_lightdir()
	loop_interact()
	loop_action_button()
	
	if movedir.length() == 1:
		ray.cast_to = movedir * 8
	
	if movedir == Vector2.ZERO:
		anim_switch("idle")
	elif is_on_wall() && ray.is_colliding() && !ray.get_collider().is_in_group("nopush"):
		anim_switch("push")
	else:
		anim_switch("walk")

func state_swing() -> void:
	anim_switch("swing")
	loop_movement()
	loop_damage()
	movedir = Vector2.ZERO

func state_hold() -> void:
	loop_controls()
	loop_movement()
	loop_damage()
	if movedir != Vector2(0, 0):
		anim_switch("walk")
	else:
		anim_switch("idle")
	
	if !has_node("Sword"):
		state = "default"

func state_spin() -> void:
	anim_switch("spin")
	loop_movement()
	loop_damage()
	movedir = Vector2.ZERO

func state_fall() -> void:
	anim_switch("jump")
	position.y += 100 * get_physics_process_delta_time()
	
	$CollisionShape2D.disabled = true
	var colliding: bool = false
	for body in hitbox.get_overlapping_bodies():
		if body is TileMap:
			colliding = true
	if !colliding:
		$CollisionShape2D.disabled = false
		sfx.play(preload("res://player/player_land.wav"))
		state = "default"

func state_menu() -> void:
	if Input.is_action_just_pressed(controller.SELECT) && network.current_map.get_node("HUD/Inventory"):
		network.current_map.get_node("HUD/Inventory").queue_free()
		state = "default"
	elif Input.is_action_just_pressed("TOGGLE_CHAT") && network.current_map.get_node("HUD/Chat"):
		network.current_map.get_node("HUD/Chat").queue_free()
		state = "default"

func loop_controls() -> void:
	movedir = Vector2.ZERO
	
	var LEFT: bool = Input.is_action_pressed(controller.LEFT)
	var RIGHT: bool = Input.is_action_pressed(controller.RIGHT)
	var UP: bool = Input.is_action_pressed(controller.UP)
	var DOWN: bool = Input.is_action_pressed(controller.DOWN)
	
	movedir.x = -int(LEFT) + int(RIGHT)
	movedir.y = -int(UP) + int(DOWN)

func loop_interact() -> void:
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.is_in_group("interact") && Input.is_action_just_pressed(controller.A) && action_cooldown == 0:
			collider.interact(self)
			action_cooldown = 3
		elif collider.is_in_group("cliff") && spritedir == "Down":
			position.y += 2
			sfx.play(preload("res://player/player_jump.wav"))
			state = "fall"
		elif movedir != Vector2.ZERO && is_on_wall() && collider.is_in_group("pushable"):
			collider.interact(self)
			push_target = collider
		elif push_target:
			push_target.stop_interact()
			push_target = null
	elif push_target:
		push_target.stop_interact()
		push_target = null
		
func loop_action_button() -> void:
	if action_cooldown == 0:
		for btn in ["B", "X", "Y"]:
			if Input.is_action_just_pressed(btn) && equip_slot[btn] != "":
				use_item(global.get_item_path(equip_slot[btn]), btn)
				for peer in network.map_peers:
					rpc_id(peer, "use_item", global.get_item_path(equip_slot[btn]), btn)
				
		if Input.is_action_just_pressed(controller.SELECT):
			show_inventory()
			state = "menu"
		elif Input.is_action_just_pressed("TOGGLE_CHAT") || Input.is_action_just_pressed(controller.START):
			show_chat()
			state = "menu"
		
func show_inventory() -> void:
	var inventory = preload("res://ui/inventory/inventory.tscn").instance()
	network.current_map.get_node("HUD").add_child(inventory)
	inventory.player = self
	inventory.start()
	
func show_chat() -> void:
	var chat = preload("res://ui/chat/chat.tscn").instance()
	network.current_map.get_node("HUD").add_child(chat)
	chat.message_log = chat_messages
	chat.start()

func connect_camera() -> void:
	camera.connect("screen_change_started", self, "screen_change_started")
	camera.connect("screen_change_completed", self, "screen_change_completed")
	camera.connect("lighting_mode_changed", self, "lighting_mode_changed")

func screen_change_started() -> void:
	set_physics_process(false)
	room.remove_entity(self)

func screen_change_completed() -> void:
	set_physics_process(true)
	room = network.get_room(position)
	room.add_entity(self)
	
func lighting_mode_changed(energy: float) -> void:
	if !is_network_master():
		return
	
	$Tween.interpolate_property($Light2D, "energy", $Light2D.energy, energy, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0.2)
	$Tween.start()
	
	yield($Tween, "tween_all_completed")
	
	for peer in network.map_peers:
		rpc_id(peer, "update_light_energy", energy)
	
	#TOOD add any other lighting effects here

remote func update_light_energy(energy: float) -> void:
	$Light2D.energy = energy

func _on_HoldTimer_timeout() -> void:
	spinAtk = true
	sfx.play(preload("res://items/tink.wav")) # get better sfx

func player_entered(id) -> void:
	if is_network_master():
		rset_id(id, "puppet_spritedir", spritedir)
		rpc_id(id, "update_light_energy", $Light2D.energy)

extends Entity

onready var ray = $RayCast2D

var action_cooldown = 0
var push_target = null

var inventory_node = preload("res://ui/inventory.tscn").instance()
var MAX_ITEMS = 35
var has_item = []
var equip_slot = {"X": -1, "Y": -1, "A": -1, "B": 0}

var item_resources = ["res://items/sword.tscn", "res://items/arrow.tscn"]

var spinAtk = false
onready var holdTimer = $HoldTimer


func _ready():
	puppet_pos = position
	puppet_spritedir = "Down"
	puppet_anim = "idleDown"
	
	for i in range(MAX_ITEMS+1):
		has_item.append(false)
	has_item[0] = true
	has_item[1] = true  #Not a real item, use at own risk
	
	inventory_node.MAX_SELECT = MAX_ITEMS
	
	add_to_group("player")
	ray.add_exception(hitbox)
	
	connect_camera()
	
	$PlayerName.visible = settings.get_pref("show_name_tags")
	
	if is_network_master():
		var hud = get_parent().get_node("HUD")
		hud.player = self
		hud.initialize()

func initialize():
	if is_network_master():
		camera.initialize(self)
		
func set_player_label(player_name):
	$PlayerName.text = player_name

func _physics_process(delta):
	# puppet
	if !is_network_master():
		position = puppet_pos
		spritedir = puppet_spritedir
		sprite.texture = texture_default
		
		if anim.current_animation != puppet_anim:
			anim.play(puppet_anim)
		
		var flip = (spritedir == "Left")
		if sprite.flip_h != flip:
			sprite.flip_h = flip
		
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
		"inventory":
			state_inventory()
	
	if action_cooldown > 0:
		action_cooldown -= 1
	
	#if movedir.length() > 1:
	#	$Sprite.global_position = global_position.snapped(Vector2(1,1))

func state_default():
	loop_controls()
	loop_movement()
	loop_damage()
	loop_spritedir()
	loop_interact()
	loop_inventory()
	
	if movedir.length() == 1:
		ray.cast_to = movedir * 8
	
	if movedir == Vector2.ZERO:
		anim_switch("idle")
	elif is_on_wall() && ray.is_colliding() && !ray.get_collider().is_in_group("nopush"):
		anim_switch("push")
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
	if movedir != Vector2(0,0):
		anim_switch("walk")
	else:
		anim_switch("idle")
	
	if !Input.is_action_pressed("A") && !Input.is_action_pressed("B"):
		state = "default"

func state_spin():
	anim_switch("spin")
	loop_movement()
	loop_damage()
	movedir = Vector2.ZERO

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
			action_cooldown = 3
		elif collider.is_in_group("cliff") && spritedir == "Down":
			position.y += 2
			sfx.play(preload("res://player/player_jump.wav"), 20)
			state = "fall"
		elif collider.is_in_group("subitem"):
			collider.on_pickup(self)
		elif movedir != Vector2.ZERO && is_on_wall() && collider.is_in_group("pushable"):
			collider.interact(self)
			push_target = collider
		elif push_target:
			push_target.stop_interact()
			push_target = null
	elif push_target:
		push_target.stop_interact()
		push_target = null
		
func loop_inventory():
	if Input.is_action_just_pressed("B") && action_cooldown == 0 && equip_slot["B"] >= 0:
		use_item(item_resources[equip_slot["B"]], "B")
		for peer in network.map_peers:
			rpc_id(peer, "use_item", item_resources[equip_slot["B"]], "B")
			
	elif Input.is_action_just_pressed("A") && action_cooldown == 0 && equip_slot["A"] >= 0:
		use_item(item_resources[equip_slot["A"]], "A")
		for peer in network.map_peers:
			rpc_id(peer, "use_item", item_resources[equip_slot["A"]], "A")
			
	elif Input.is_action_just_pressed("X") && action_cooldown == 0 && equip_slot["X"] >= 0:
		use_item(item_resources[equip_slot["X"]], "X")
		for peer in network.map_peers:
			rpc_id(peer, "use_item", item_resources[equip_slot["X"]], "X")
			
	elif Input.is_action_just_pressed("Y") && action_cooldown == 0 && equip_slot["Y"] >= 0:
		use_item(item_resources[equip_slot["Y"]], "Y")
		for peer in network.map_peers:
			rpc_id(peer, "use_item", item_resources[equip_slot["Y"]], "Y")
			
	elif Input.is_action_just_pressed("ui_select") && action_cooldown == 0:
		show_inventory()
		
func show_inventory():
	action_cooldown = 5
	state = "inventory"
	inventory_node.scroll_down(self)
	
func hide_inventory():
	inventory_node.scroll_up(self);
	
func state_inventory():
	if Input.is_action_just_pressed("ui_select"):
		hide_inventory()
func connect_camera():
	camera.connect("screen_change_started", self, "screen_change_started")
	camera.connect("screen_change_completed", self, "screen_change_completed")

func screen_change_started():
	set_physics_process(false)

func screen_change_completed():
	set_physics_process(true)


func _on_HoldTimer_timeout():
	spinAtk = true
	sfx.play(preload("res://items/tink.wav"), 20) # get better sfx

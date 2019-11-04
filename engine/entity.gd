extends KinematicBody2D

class_name Entity

# ATTRIBUTES
export(String, "ENEMY", "PLAYER", "TRAP") var TYPE = "ENEMY"
export(float, 0.5, 20, 0.5) var MAX_HEALTH = 1
export(int) var SPEED = 70
export(float, 0, 20, 0.5) var DAMAGE = 0.5
export(String, FILE) var HURT_SOUND = "res://enemies/enemy_hurt.wav"

# MOVEMENT
var movedir = Vector2(0,0)
var knockdir = Vector2(0,0)
var spritedir = "Down"
var last_movedir = Vector2(0,1)

# COMBAT
var health = MAX_HEALTH
signal health_changed
signal hitstun_end
var hitstun = 0

# NETWORK
puppet var puppet_pos
puppet var puppet_spritedir
puppet var puppet_anim

var state = "default"

var home_position = Vector2(0,0)

onready var anim = $AnimationPlayer
onready var sprite = $Sprite
var hitbox # to be defined by create_hitbox()

onready var camera = get_parent().get_node("Camera")

var texture_default = null
var entity_shader = preload("res://engine/entity.shader")

var room : network.Room

func _ready():
	
	texture_default = sprite.texture
	
	# Create default material if one does not exist...
	if !sprite.material:
		sprite.material = ShaderMaterial.new()
		sprite.material.set_shader(entity_shader)
	
	add_to_group("entity")
	health = MAX_HEALTH
	home_position = position
	create_hitbox()
	
	network.current_map.connect("player_entered", self, "player_entered")
	
	room = network.get_room(position)
	room.add_entity(self)

func create_hitbox():
	var new_hitbox = Area2D.new()
	add_child(new_hitbox)
	new_hitbox.name = "Hitbox"
	
	var new_collision = CollisionShape2D.new()
	new_hitbox.add_child(new_collision)
	
	var new_shape = RectangleShape2D.new()
	new_collision.shape = new_shape
	new_shape.extents = $CollisionShape2D.shape.extents + Vector2(1,1)
	
	hitbox = new_hitbox

func loop_network():
	set_network_master(network.map_owners[network.current_map.name])
	if !network.map_owners[network.current_map.name] == get_tree().get_network_unique_id():
		puppet_update()
	if position == Vector2(0,0):
		hide()
	else:
		show()

func puppet_update():
	pass

func is_scene_owner():
	if !network.map_owners.keys().has(network.current_map.name):
		return false
	if network.map_owners[network.current_map.name] == get_tree().get_network_unique_id():
		return true
	return false

func is_dead():
	if health <= 0 && hitstun == 0:
		return true
	return false

func loop_movement():
	var motion
	if hitstun == 0:
		motion = movedir.normalized() * SPEED
	else:
		motion = knockdir.normalized() * 125
	
	# This is optimal, but it doesn't sync players on initial connection.
	# if move_and_slide(motion) != Vector2.ZERO:
	# 	sync_property("puppet_pos", position)
	
	move_and_slide(motion)
	sync_property_unreliable("puppet_pos", position)
	
	if movedir != Vector2.ZERO:
		last_movedir = movedir

func loop_spritedir():
	var old_spritedir = spritedir
	
	match movedir:
		Vector2.LEFT:
			spritedir = "Left"
		Vector2.RIGHT:
			spritedir = "Right"
		Vector2.UP:
			spritedir = "Up"
		Vector2.DOWN:
			spritedir = "Down"
	
	if old_spritedir != spritedir:
		sync_property("puppet_spritedir", spritedir)
	
	var flip = spritedir == "Left"
	if sprite.flip_h != flip:
		sprite.flip_h = flip

func loop_damage():
	sprite.texture = texture_default
	sprite.scale.x = 1
	
	if hitstun > 1:
		hitstun -= 1
		rpc_unreliable("hurt_texture")
	elif hitstun == 1:
		rpc("default_texture")
		emit_signal("hitstun_end")
		hitstun -= 1
	
	for area in hitbox.get_overlapping_areas():
		if area.name != "Hitbox":
			continue
		var body = area.get_parent()
		if !body.get_groups().has("entity") && !body.get_groups().has("item"):
			continue
		if hitstun == 0 && body.get("DAMAGE") > 0 && body.get("TYPE") != TYPE:
			update_health(-body.DAMAGE)
			hitstun = 10
			knockdir = global_position - body.global_position
			sfx.play(load(HURT_SOUND))
			
			if body.has_method("hit"):
				body.rpc("hit")
				body.hit()

func update_health(delta):
	health = max(min(health + delta, MAX_HEALTH), 0)
	emit_signal("health_changed")

sync func hurt_texture():
	sprite.material.set_shader_param("is_hurt", true)

sync func default_texture():
	sprite.material.set_shader_param("is_hurt", false)

func anim_switch(animation):
	var newanim = str(animation,spritedir)
	if ["Left","Right"].has(spritedir):
		newanim = str(animation,"Side")
	if anim.current_animation != newanim:
		sync_property("puppet_anim", newanim)
		anim.play(newanim)

sync func use_item(item, input):
	var newitem = load(item).instance()
	var itemgroup = str(item,name)
	newitem.add_to_group(itemgroup)
	newitem.add_to_group(name)
	add_child(newitem)
	
	if is_network_master():
		newitem.set_network_master(get_tree().get_network_unique_id())
	
	if get_tree().get_nodes_in_group(itemgroup).size() > newitem.MAX_AMOUNT:
		newitem.delete()
		return
	
	newitem.input = input
	newitem.start()

func choose_subitem(possible_drops, drop_chance):
	randomize()
	var will_drop = randi() % 100 + 1
	if will_drop <= drop_chance:
		var dropped = possible_drops[randi() % possible_drops.size()]
		var drop_choice = 0
		match dropped:
			"HEALTH":
				drop_choice = "res://droppables/heart.tscn"
			"RUPEE":
				drop_choice = "res://droppables/rupee.tscn"
		
		if typeof(drop_choice) != TYPE_INT:
			var subitem_name = str(randi()) # we need to sync names to ensure the subitem can rpc to the same thing for others
			network.current_map.spawn_subitem(drop_choice, global_position, subitem_name) # has to be from game.gd bc the node might have been freed beforehand
			for peer in network.map_peers:
				network.current_map.rpc_id(peer, "spawn_subitem", drop_choice, global_position, subitem_name)

func send_chat_message(source, text):
	network.current_map.receive_chat_message(source, text)
	rpc("receive_chat_message", source, text)

sync func enemy_death():
	if is_scene_owner():
		choose_subitem(["HEALTH", "RUPEE"], 100)
	room.remove_entity(self)
	var death_animation = preload("res://enemies/enemy_death.tscn").instance()
	death_animation.global_position = global_position
	get_parent().add_child(death_animation)
	
	set_dead()

remote func set_dead():
	hide()
	set_physics_process(false)
	set_process(false)
	home_position = Vector2(0,0)
	position = Vector2(0,0)
	health = -1

func rset_map(property, value):
	for peer in network.map_peers:
		rset_id(peer, property, value)

func rset_unreliable_map(property, value):
	for peer in network.map_peers:
		rset_unreliable_id(peer, property, value)

func sync_property(property, value):
	if TYPE == "PLAYER":
		if !is_network_master(): 
			return
	else: 
		if !is_scene_owner():
			return
	rset_map(property, value)

func sync_property_unreliable(property, value):
	if TYPE == "PLAYER":
		if !is_network_master(): 
			return
	else: 
		if !is_scene_owner():
			return
	rset_unreliable_map(property, value)

func player_entered(id):
	if is_scene_owner() && is_dead():
		rpc_id(id, "set_dead")

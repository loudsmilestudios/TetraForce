extends KinematicBody2D

class_name Entity

# ATTRIBUTES
export(String, "ENEMY", "PLAYER") var TYPE = "ENEMY"
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
var hitstun = 0

var state = "default"

var home_position = Vector2(0,0)

onready var anim = $AnimationPlayer
onready var sprite = $Sprite
var hitbox # to be defined by create_hitbox()

onready var camera = get_parent().get_node("Camera")

var texture_default = null
var entity_shader = preload("res://engine/entity.shader")

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
	
	if TYPE == "ENEMY":
		add_to_group("enemy")
		set_collision_layer_bit(0,0)
		set_collision_mask_bit(0,0)
		set_collision_layer_bit(1,1)
		set_collision_mask_bit(1,1)

func create_hitbox():
	var new_hitbox = Area2D.new()
	add_child(new_hitbox)
	
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
	if network.map_owners[network.current_map.name] == get_tree().get_network_unique_id():
		return true
	return false

func loop_movement():
	var motion
	if hitstun == 0:
		motion = movedir.normalized() * SPEED
	else:
		motion = knockdir.normalized() * 125
	move_and_slide(motion)
	
	if movedir != Vector2.ZERO:
		last_movedir = movedir

func loop_spritedir():
	match movedir:
		Vector2.LEFT:
			spritedir = "Left"
		Vector2.RIGHT:
			spritedir = "Right"
		Vector2.UP:
			spritedir = "Up"
		Vector2.DOWN:
			spritedir = "Down"
	sprite.flip_h = spritedir == "Left"

func loop_damage():
	health = min(health, MAX_HEALTH)
	sprite.texture = texture_default
	
	if hitstun > 1:
		hitstun -= 1
		rpc_unreliable("hurt_texture")
	elif hitstun == 1:
		rpc("default_texture")
		hitstun -= 1
	else:
		if TYPE == "ENEMY" && health <= 0:
			rpc("enemy_death")
	
	for area in hitbox.get_overlapping_areas():
		var body = area.get_parent()
		if !body.get_groups().has("entity") && !body.get_groups().has("item"):
			continue
		if hitstun == 0 && body.get("DAMAGE") > 0 && body.get("TYPE") != TYPE:
			health -= body.DAMAGE
			hitstun = 10
			knockdir = global_position - body.global_position
			sfx.play(load(HURT_SOUND))
			
			if body.has_method("hit"):
				body.rpc("hit")
				body.hit()

sync func hurt_texture():
	sprite.material.set_shader_param("is_hurt", true)

sync func default_texture():
	sprite.material.set_shader_param("is_hurt", false)

func anim_switch(animation):
	var newanim = str(animation,spritedir)
	if ["Left","Right"].has(spritedir):
		newanim = str(animation,"Side")
	if anim.current_animation != newanim:
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

sync func enemy_death():
	var death_animation = preload("res://enemies/enemy_death.tscn").instance()
	death_animation.global_position = global_position
	get_parent().add_child(death_animation)
	queue_free()

func rset_map(property, value):
	for peer in network.map_peers:
		rset_id(peer, property, value)

func rset_unreliable_map(property, value):
	for peer in network.map_peers:
		rset_unreliable_id(peer, property, value)

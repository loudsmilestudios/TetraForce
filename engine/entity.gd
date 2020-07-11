extends KinematicBody2D

class_name Entity

# ATTRIBUTES
export(String, "ENEMY", "PLAYER", "TRAP") var TYPE = "ENEMY"
export(float, 0.5, 20, 0.5) var MAX_HEALTH = 1
export(int) var SPEED = 70
export(float, 0, 20, 0.5) var DAMAGE = 0.5

# MOVEMENT
var movedir = Vector2(0,0)
var knockdir = Vector2(0,0)
var spritedir = "Down"
var last_movedir = Vector2(0,1)

# COMBAT
var health = MAX_HEALTH
var hitstun = 0
signal health_changed
signal hitstun_end


# NETWORK
puppet var puppet_pos : Vector2 = Vector2(0,0)
puppet var puppet_spritedir : String = "Down"
puppet var puppet_anim : String = "idleDown"

var state = "default"
var home_position = Vector2(0,0)

onready var anim = $AnimationPlayer
onready var sprite = $Sprite
var hitbox : Area2D
var camera

func _ready():
	add_to_group("entity")
	if !sprite.material:
		sprite.material = ShaderMaterial.new()
		sprite.material.set_shader(preload("res://engine/entity.shader"))
	health = MAX_HEALTH
	home_position = position
	create_hitbox()
	network.current_map.connect("player_entered", self, "player_entered")


func create_hitbox() -> void:
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
	set_network_master(network.map_hosts[network.current_map.name])
	if !network.map_hosts[network.current_map.name] == get_tree().get_network_unique_id():
		puppet_update()
	if position == Vector2(0,0):
		hide()
	else:
		show()

func loop_movement():
	var motion
	if hitstun == 0:
		motion = movedir.normalized() * SPEED
	else:
		motion = knockdir.normalized() * 125
	
	move_and_slide(motion)
	mset_unreliable("puppet_pos", position)
	
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
		mset("puppet_spritedir", spritedir)
	
	sprite.flip_h = (spritedir == "Left")

func loop_damage():
	if hitstun > 1:
		hitstun -= 1
		if sprite.material.get_shader_param("is_hurt") == false:
			for peer in network.map_peers:
				rpc_id(peer, "set_hurt_texture", true)
			set_hurt_texture(true)
	elif hitstun == 1:
		if sprite.material.get_shader_param("is_hurt") == true:
			for peer in network.map_peers:
				rpc_id(peer, "set_hurt_texture", false)
			set_hurt_texture(false)
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
			
			if body.has_method("hit"):
				for peer in network.map_peers:
					rpc_id(peer, "hit")
				body.hit()

func update_health(amount):
	health = max(min(health + amount, MAX_HEALTH), 0)
	emit_signal("health_changed")
	for peer in network.map_peers:
		rpc_id(peer, "set_health", health)

sync func set_hurt_texture(h : bool):
	sprite.material.set_shader_param("is_hurt", h)

func anim_switch(animation):
	var newanim: String = str(animation, spritedir)
	if ["Left","Right"].has(spritedir):
		newanim = str(animation, "Side")
	if anim.current_animation != newanim:
		mset("puppet_anim", newanim)
		anim.play(newanim)

sync func use_item(item, input):
	var newitem = load(item).instance()
	var itemgroup = str(item, name)
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

func mset(property, value): # map rset, only rsets to map peers
	for peer in network.map_peers:
		rset_id(peer, property, value)

func mset_unreliable(property, value): # same but unreliable
	for peer in network.map_peers:
		rset_unreliable_id(peer, property, value)

remote func set_health(amount):
	health = amount

func puppet_update():
	pass

func player_entered(id):
	pass

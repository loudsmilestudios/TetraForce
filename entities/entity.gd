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
var last_safe_pos = position

# COMBAT
var health = MAX_HEALTH setget set_health
var hitstun = 0
var invunerable = 0
var hurt_sfx = "hit_hurt"
signal health_changed
signal update_count

var state = "default"
var home_position = Vector2(0,0)

onready var anim = $AnimationPlayer
onready var sprite = $Sprite
var hitbox : Area2D
var center : Area2D
var camera
var tween
var walkfx
onready var map = get_parent()

var pos = Vector2(0,0) setget position_changed
var animation = "idleDown" setget animation_changed

signal update_persistent_state

signal killed
signal damaged

func _ready():
	set_process(false)
	add_to_group("entity")
	
	map = get_game(self)
	
	if !sprite.material:
		sprite.material = ShaderMaterial.new()
		sprite.material.set_shader(preload("res://entities/entity.shader"))
	health = MAX_HEALTH
	home_position = position
	pos = position
	create_hitbox()
	create_center()
	create_tween()
	walkfx = preload("res://effects/walkfx.tscn").instance()
	add_child(walkfx)
	#map.connect("player_entered", self, "player_entered")
	set_collision_layer_bit(10, 1)
	#set_collision_mask_bit(10, 1)
	set_process(true)

func get_game(node):
	var game = node.get_parent()
	while game != null and not game.has_method("is_game"):
		game = game.get_parent()
	return game

func _process(delta):
	walkfx.hide()
	for body in center.get_overlapping_bodies():
		if body.is_in_group("fxtile"):
			walkfx.show()
			walkfx.frame = sprite.frame % 2
			walkfx.texture = body.walkfx_texture

func create_hitbox():
	var new_hitbox = Area2D.new()
	add_child(new_hitbox)
	new_hitbox.name = "Hitbox"
	
	var new_collision = CollisionShape2D.new()
	new_hitbox.add_child(new_collision)
	
	var new_shape = CapsuleShape2D.new()
	new_collision.shape = new_shape
	new_shape.radius = $CollisionShape2D.shape.radius + 1
	new_shape.height = $CollisionShape2D.shape.height + 1
	
	new_hitbox.set_collision_layer_bit(7,1)
	new_hitbox.set_collision_mask_bit(7,1)
	
	hitbox = new_hitbox

func create_center():
	var new_center = Area2D.new()
	add_child(new_center)
	new_center.name = "Center"
	
	var new_collision = CollisionShape2D.new()
	new_center.add_child(new_collision)
	
	var new_shape = RectangleShape2D.new()
	new_collision.shape = new_shape
	new_shape.extents = Vector2(1,1)
	
	# tall_grass
	new_center.set_collision_layer_bit(0,0)
	new_center.set_collision_mask_bit(0,0)
	new_center.set_collision_layer_bit(5,1)
	new_center.set_collision_mask_bit(5,1)
	new_center.set_collision_layer_bit(6,1)
	new_center.set_collision_mask_bit(6,1)
	new_center.set_collision_layer_bit(7,1)
	new_center.set_collision_mask_bit(7,1)
	
	new_center.position.y += 6
	
	center = new_center

func create_tween():
	var new_tween = Tween.new()
	add_child(new_tween)
	tween = new_tween

func loop_movement():
	var motion
	if hitstun == 0:
		motion = movedir.normalized() * SPEED
	else:
		motion = knockdir.normalized() * 125
	
	move_and_slide(motion)
	
	pos = position
	
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
	
	sprite.flip_h = (spritedir == "Left")

func loop_damage():
	if hitstun > 1:
		hitstun -= 1
	elif hitstun == 1:
		if sprite.material.get_shader_param("is_hurt") == true:
			set_hurt_texture(false)
			network.peer_call(self, "set_hurt_texture", [false])
		check_for_death()
		hitstun -= 1
	if invunerable > 1:
		invunerable -= 1
	elif invunerable == 1:
		if is_in_group("invunerable"):
			remove_from_group("invunerable")
		#anim.stop()
		invunerable -= 1
	
	if !hitbox.monitoring:
		return
	for area in hitbox.get_overlapping_areas():
		if area.name != "Hitbox":
			continue
		var body = area.get_parent()
		if !body.get_groups().has("entity"):
			continue
		if body.get("DAMAGE") > 0 && body.get("TYPE") != TYPE:
			damage(body.DAMAGE, global_position - body.global_position, body)

func loop_holes():
	if get_collision_layer_bit(7) == true:
		return
	for body in center.get_overlapping_bodies():
		if body is Holes:
			var hole_origin = body.map_to_world(body.world_to_map(position.round() + Vector2(0,6))) + Vector2(8,8)
			var hole_hitbox = Rect2(hole_origin - Vector2(5,5), Vector2(10,10))
			position = position.linear_interpolate(hole_origin, 0.1) # there's a way to lerp w/ delta time i forgot it tho
			position += Vector2(0, rand_range(-1,0))
			if hole_hitbox.has_point(position + Vector2(0,4)):
				create_hole_fx(hole_origin)
				network.peer_call(self, "create_hole_fx", [hole_origin])
				hole_fall()
				network.peer_call(self, "hole_fall")

func hole_fall():
	pass

func create_hole_fx(pos):
	var hole_fx = preload("res://effects/hole_falling.tscn").instance()
	map.add_child(hole_fx)
	hole_fx.position = pos
	sfx.play("fall")
	
func create_drowning_fx(pos):
	var drowning_fx = preload("res://effects/drowning.tscn").instance()
	map.add_child(drowning_fx)
	drowning_fx.position = pos
	sfx.play("drown")

func damage(amount, dir, damager=null):
	if is_in_group("invunerable"):
		return
	if hitstun == 0 && state != "menu":
		if amount != 0:
			sfx.play(hurt_sfx)
			set_hurt_texture(true)
			network.peer_call(self, "set_hurt_texture", [true])
			if TYPE == "PLAYER":
				add_to_group("invunerable")
				invunerable = 60
		hitstun = 10
		update_health(-amount)
		knockdir = dir
		if damager != null:
			emit_signal("damaged", damager)
			if health <= 0:
				emit_signal("killed", damager)

func update_health(amount):
	health = max(min(health + amount, MAX_HEALTH), 0)
	emit_signal("health_changed")

func check_for_death():
	pass

remote func set_hurt_texture(h):
	sprite.material.set_shader_param("is_hurt", h)

func anim_switch(a):
	var newanim: String = str(a, spritedir)
	if ["Left","Right"].has(spritedir):
		newanim = str(a, "Side")
	if anim.current_animation != newanim:
		anim.play(newanim)
	animation = newanim

sync func use_weapon(weapon_name, input="A"):
	var weapon = global.weapons_def[weapon_name]
	var new_weapon = load(weapon.path).instance()
	var weapon_group = str(weapon_name, name)
	new_weapon.add_to_group(weapon_group)
	new_weapon.add_to_group(name)
	add_child(new_weapon)
	
	new_weapon.set_network_master(get_network_master())
	
	if get_tree().get_nodes_in_group(weapon_group).size() > new_weapon.MAX_AMOUNT:
		new_weapon.delete()
		return
	
	if is_network_master() && is_in_group("player") && weapon.ammo_type != "":
		if global.ammo[weapon.ammo_type] <= 0:
			new_weapon.delete()
			yield(get_tree().create_timer(0.05), "timeout") # hacky
			network.peer_call(self, "remove_last_item", [weapon_group])
			return
		global.ammo[weapon.ammo_type] -= 1
		emit_signal("update_count")
	
	new_weapon.input = input
	new_weapon.start()

func remove_last_item(group):
	get_tree().get_nodes_in_group(group).back().queue_free()

func position_changed(value):
	pos = value
	tween.interpolate_property(self, "position", position, pos, network.tick_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func animation_changed(value):
	animation = value
	if anim.current_animation != value:
		anim.play(value)

func set_health(value):
	health = value
	
func reset_collision():
	$CollisionShape2D.disabled = false

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

# COMBAT
var health = MAX_HEALTH
var hitstun = 0

var state = "default"

var home_position = Vector2(0,0)

onready var anim = $AnimationPlayer
onready var sprite = $Sprite
onready var hitbox = $Hitbox

onready var camera = get_parent().get_node("Camera")

var texture_default = null
var texture_hurt = null
var animation = "idleDown"

func _ready():
	texture_default = sprite.texture
	texture_hurt = load(sprite.texture.get_path().replace(".png","_hurt.png"))
	add_to_group("entity")
	health = MAX_HEALTH
	home_position = position
	
	if TYPE == "ENEMY":
		add_to_group("enemy")

func loop_movement():
	var motion
	if hitstun == 0:
		motion = movedir.normalized() * SPEED
	else:
		motion = knockdir.normalized() * 125
	move_and_slide(motion)

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
	
	if hitstun > 0:
		hitstun -= 1
		rpc_unreliable("hurt_texture")
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
			
			body.rpc("hit")

sync func hurt_texture():
	sprite.texture = texture_hurt

func anim_switch(animation):
	var newanim = str(animation,spritedir)
	if ["Left","Right"].has(spritedir):
		newanim = str(animation,"Side")
	if anim.current_animation != newanim:
		anim.play(newanim)

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

# put into helper script pls
static func rand_direction():
	var new_direction = randi() % 4 + 1
	match new_direction:
		1:
			return Vector2.LEFT
		2:
			return Vector2.RIGHT
		3:
			return Vector2.UP
		4:
			return Vector2.DOWN

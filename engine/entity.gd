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

# NETWORK
puppet var puppet_pos : Vector2 = Vector2(0,0)
puppet var puppet_spritedir : String = "Down"
puppet var puppet_anim : String = "idleDown"

var state = "default"

onready var anim = $AnimationPlayer
onready var sprite = $Sprite
var hitbox : Area2D
var camera

func _ready():
	add_to_group("entity")
	create_hitbox()

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

func anim_switch(animation):
	var newanim: String = str(animation, spritedir)
	if ["Left","Right"].has(spritedir):
		newanim = str(animation, "Side")
	if anim.current_animation != newanim:
		mset("puppet_anim", newanim)
		anim.play(newanim)

func mset(property, value): # map rset, only rsets to map peers
	for peer in network.map_peers:
		rset_id(peer, property, value)

func mset_unreliable(property, value): # same but unreliable
	for peer in network.map_peers:
		rset_unreliable_id(peer, property, value)







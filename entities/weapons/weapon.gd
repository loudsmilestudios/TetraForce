extends Node2D

class_name Weapon

var TYPE = null
var input = null
var user = null

@export var DAMAGE = 0.5 # (float, 0, 20, 0.5)
@export var MAX_AMOUNT = 1 # (int, 1, 20)
@export var delete_on_hit: bool = false

func _ready():
	user = get_parent()
	TYPE = get_parent().TYPE
	add_to_group("item")
	set_physics_process(false)
	set_multiplayer_authority(get_parent().get_multiplayer_authority())

func hit():
	if delete_on_hit:
		delete()

func damage(body):
	var knockdir = body.global_position - global_position
	if is_multiplayer_authority() && network.is_map_host():
		if body is Player && body.name != str(network.pid):
			network.peer_call_id(int(body.name), body, "damage", [DAMAGE, knockdir])
		else:
			body.damage(DAMAGE, knockdir, self)
	elif network.is_map_host():
		body.damage(DAMAGE, knockdir, self)
	elif is_multiplayer_authority():
		if body is Player:
			network.peer_call_id(int(body.name), body, "damage", [DAMAGE, knockdir])
		else:
			network.peer_call_id(network.get_map_host(), body, "damage", [DAMAGE, knockdir])
	if delete_on_hit:
		network.peer_call(self, "delete")
		delete()

func delete():
	if is_multiplayer_authority():
		network.peer_call(self, "queue_free")
	queue_free()

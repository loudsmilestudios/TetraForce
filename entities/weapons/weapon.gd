extends Node2D

class_name Weapon

var TYPE = null
var input = null
var user = null

export(float, 0, 20, 0.5) var DAMAGE = 0.5
export(int, 1, 20) var MAX_AMOUNT = 1
export(bool) var delete_on_hit = false

func _ready():
	user = get_parent()
	TYPE = get_parent().TYPE
	add_to_group("item")
	set_physics_process(false)
	set_network_master(get_parent().get_network_master())

func hit():
	if delete_on_hit:
		delete()

func damage(body):
	var knockdir = body.global_position - global_position
	if is_network_master() && network.is_map_host():
		if body is Player && body.name != str(network.pid):
			network.peer_call_id(int(body.name), body, "damage", [DAMAGE, knockdir])
		else:
			body.damage(DAMAGE, knockdir, self)
	elif network.is_map_host():
		body.damage(DAMAGE, knockdir, self)
	elif is_network_master():
		if body is Player:
			network.peer_call_id(int(body.name), body, "damage", [DAMAGE, knockdir])
		else:
			network.peer_call_id(network.get_map_host(), body, "damage", [DAMAGE, knockdir])
	if delete_on_hit:
		network.peer_call(self, "delete")
		delete()

func delete():
	if is_network_master():
		network.peer_call(self, "queue_free")
	queue_free()

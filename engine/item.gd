extends Node2D

class_name Item

var TYPE = null
var input = null

export(float, 0, 20, 0.5) var DAMAGE = 0.5
export(int, 1, 20) var MAX_AMOUNT = 1
export(bool) var delete_on_hit = false

func _ready():
	TYPE = get_parent().TYPE
	add_to_group("item")
	set_physics_process(false)

sync func hit():
	if delete_on_hit:
		for peer in network.map_peers:
			rpc_id(peer, "delete")

sync func delete():
	queue_free()

func mset(property, value): # map rset, only rsets to map peers
	for peer in network.map_peers:
		rset_id(peer, property, value)

func mset_unreliable(property, value): # same but unreliable
	for peer in network.map_peers:
		rset_unreliable_id(peer, property, value)

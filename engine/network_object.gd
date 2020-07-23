extends Node

export(bool) var require_map_host = true
export(Dictionary) var update_properties = {}
export(Dictionary) var enter_properties = {}

func _ready():
	get_parent().get_parent().connect("player_entered", self, "player_entered")
	network.tick.connect("timeout", self, "_tick")
	
func _tick():
	if require_map_host && !network.is_map_host():
		return
	if is_network_master():
		update_sync()

func player_entered(id):
	#print(id)
	if require_map_host && !network.is_map_host():
		return
	if id == network.pid:
		return
	for key in enter_properties.keys():
		enter_properties[key] = get_parent().get(str(key))
	network.peer_call_id(id, self, "_receive_update", [enter_properties])

func update_sync():
	for key in update_properties.keys():
		update_properties[key] = get_parent().get(str(key))
	network.peer_call_unreliable(self, "_receive_update", [update_properties])

func _receive_update(properties = {}):
	for key in properties.keys():
		get_parent().set(key, properties[key])

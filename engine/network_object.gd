extends Node

export(bool) var require_map_host = true
export(bool) var persistent = false
export(bool) var sync_creation = false
export(Dictionary) var update_properties = {}
export(Dictionary) var enter_properties = {}

func _ready():
	var parent = get_parent()
	if parent.has_method("get_game"):
		parent.get_game(self).connect("player_entered", self, "player_entered")
	else:
		parent.get_parent().connect("player_entered", self, "player_entered")
	network.tick.connect("timeout", self, "_tick")
	if persistent:
		get_parent().connect("update_persistent_state", self, "update_persistent_state")
		network.request_persistent_state(get_parent())

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
	if persistent:
		return
	if sync_creation:
		network.peer_create_id(id, get_parent().filename, get_parent().name, get_parent().get_parent())
		return
	update_enter_properties(id)

func update_enter_properties(id):
	for key in enter_properties.keys():
		enter_properties[key] = get_parent().get(str(key))
	network.peer_call_id(id, self, "receive_update", [enter_properties])

func update_sync():
	for key in update_properties.keys():
		update_properties[key] = get_parent().get(str(key))
	network.peer_call_unreliable(self, "receive_update", [update_properties])

func update_persistent_state():
	if !network.is_map_host():
		return
	for key in enter_properties.keys():
		enter_properties[key] = get_parent().get(str(key))
	network.persistent_set_state(get_parent().get_path(), enter_properties)

func receive_update(properties = {}):
	for key in properties.keys():
		get_parent().set(key, properties[key])

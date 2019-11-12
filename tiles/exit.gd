extends Area2D

export(String) var map: String
export(String) var player_position: String
export(String) var entrance: String

func _ready() -> void:
	connect("body_entered", self, "body_entered")

func body_entered(body) -> void:
	if body.is_in_group("player") && body.is_network_master():
		body.state = "interact"
		screenfx.play("fadewhite")
		yield(screenfx, "animation_finished")
		
		global.get_player_state()
		global.next_entrance = entrance
		
		var old_map = get_parent()
		var root = old_map.get_parent()
		
		var new_map_path = "res://maps/" + map + ".tmx"
		var new_map = load(new_map_path).instance()
		root.call_deferred("add_child", new_map)
		
		old_map.call_deferred("queue_free")

extends Area2D

export(String) var map
export(String) var player_position
export(String) var entrance

func _ready():
	connect("body_entered", self, "body_entered")

func body_entered(body):
	if body.is_in_group("player") && body.is_network_master():
		body.state = "interact"
		body.camera.set_process(false)
		screenfx.play("fadewhite")
		yield(screenfx, "animation_finished")
		
		global.next_entrance = entrance
		
		var old_map = get_parent()
		var root = old_map.get_parent()
		
		var new_map_path = "res://maps/" + map + ".tscn"
		var new_map = load(new_map_path).instance()
		root.call_deferred("add_child", new_map)
		old_map.call_deferred("queue_free")

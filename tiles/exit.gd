extends Area2D

export(String, FILE, "*.tscn") var map

func _ready():
	connect("body_entered", self, "body_entered")

func body_entered(body):
	if body.is_in_group("player") && body.is_network_master():
		body.state = "interact"
		screenfx.play("fadewhite")
		yield(screenfx, "animation_finished")
		
		global.get_player_state()
		
		var old_map = get_parent()
		var root = old_map.get_parent()
		
		var new_map = load(map).instance()
		root.call_deferred("add_child", new_map)
		
		old_map.call_deferred("queue_free")

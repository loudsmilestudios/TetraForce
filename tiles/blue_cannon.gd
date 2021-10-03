extends StaticBody2D

export(String) var spritedir = "Down"
var TYPE = "PLAYER"
var fired = false
var mouth = false

signal update_persistent_state

func _ready():
	add_to_group("interactable")
	update_spritedir()
	
func _physics_process(delta):
	pass
	
func interact(node : Entity):
	if node:
		if node.spritedir == "Up" && spritedir =="Down":
			mouth = true
		elif node.spritedir == "Down" && spritedir =="Up":
			mouth = true
		elif node.spritedir == "Left" && spritedir =="Right":
			mouth = true
		elif node.spritedir == "Right" && spritedir =="Left":
			mouth = true
		else:
			mouth = false
	if network.is_map_host():
		on_interact()
	else:
		network.peer_call_id(network.get_map_host(), self, "on_interact")
	
func on_interact():
	if $explosion.visible or $fuse.visible == true:
		return
	if fired == false && mouth == false:
		remove_from_group("interactable")
		if network.is_map_host():
			network.peer_call(self, "on_interact")
		$AnimationPlayer.play("fuse" + spritedir)
		yield(get_tree().create_timer(2.5), "timeout")
		$AnimationPlayer.play("shot" + spritedir)
		use_weapon("CannonBall")
		fired = true

sync func use_weapon(weapon_name, input="A"):
	var weapon = global.weapons_def[weapon_name]
	var new_weapon = load(weapon.path).instance()
	var weapon_group = str(weapon_name, name)
	new_weapon.add_to_group(weapon_group)
	new_weapon.add_to_group(name)
	add_child(new_weapon)
	
	new_weapon.set_network_master(get_network_master())
	
	if get_tree().get_nodes_in_group(weapon_group).size() > new_weapon.MAX_AMOUNT:
		new_weapon.delete()
		return
	
	new_weapon.input = input
	new_weapon.start()

func update_spritedir():
	match spritedir:
		"Up":
			$Sprite.frame = 2
			$CollisionShape2D.rotation_degrees = 0
			$CollisionShape2D.position.y = -4
		"Right":
			$Sprite.frame = 4
			$CollisionShape2D.rotation_degrees = 90
			$CollisionShape2D.position.x = 4
			$CollisionShape2D.position.y = -1
		"Down":
			$Sprite.frame = 0
			$CollisionShape2D.rotation_degrees = 0
			$CollisionShape2D.position.y = 4
		"Left":
			$Sprite.frame = 6
			$CollisionShape2D.rotation_degrees = 90
			$CollisionShape2D.position.x = -4
			$CollisionShape2D.position.y = -1


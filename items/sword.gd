extends Item

onready var anim = $AnimationPlayer
onready var holdTimer = $HoldTimer

var spin_attack = false
var spin_multiplier = 2 # damage *= 2


func start():
	if get_parent().is_network_master():
		anim.connect("animation_finished", self, "destroy")
		if get_parent().has_method("state_swing"):
			get_parent().state = "swing"
	
	anim.play(str("swing", get_parent().spritedir))

func destroy(animation):
	# If this is true, spin_attack animation is done, so delete stuff (no need to check inputs)
	if spin_attack: 
		network.peer_call(self, "delete")
		delete()
	
	if input != null && Input.is_action_pressed(input):
		set_physics_process(true)
		delete_on_hit = true
		holdTimer.stop()
		match get_parent().spritedir:
			"Left":
				position.x += 3
			"Right":
				position.x -= 3
			"Up":
				position.y += 4
				z_index -= 1
			"Down":
				position.y -= 3
		network.peer_call(self, "set_pos", [position])
		return
	
	network.peer_call(self, "delete")
	delete()

remote func set_pos(p_pos) -> void:
	position = p_pos

remote func flash() -> void:
	anim.play("flash")

remote func spin(p_adv) -> void:
	anim.play("spin")
	anim.advance(p_adv)
	DAMAGE *= 2

sync func delete() -> void:
	get_parent().state = "default"
	spin_attack = false
	holdTimer.stop()
	queue_free()

func _physics_process(delta) -> void:
	if get_parent().has_method("state_hold") and get_parent().state != "spin":
		get_parent().state = "hold"
		if holdTimer.is_stopped() and !spin_attack:
			holdTimer.wait_time = 0.75
			holdTimer.start()
	
	if spin_attack && get_parent().state != "spin" && anim.current_animation != "flash":
		anim.play("flash")
		network.peer_call(self, "flash")
	
	if !Input.is_action_pressed(input):
		# Spin attack
		if get_parent().has_method("state_spin") and spin_attack and get_parent().state != "spin":
			delete_on_hit = false
			get_parent().state = "spin"
			anim.play("spin")
			match get_parent().spritedir:
				"Left":
					anim.advance(0.2)
					position.x -= 4
				"Right":
					anim.advance(0.2)
					position.x += 4
					scale.x = -1
				"Up":
					anim.advance(0.08)
					position.y -= 3
				"Down":
					anim.advance(0.3)
			
			DAMAGE *= 2
			
			network.peer_call(self, "spin", [anim.current_animation_position])
			
			get_parent().anim.connect("animation_finished", self, "destroy")
			get_parent().anim.connect("animation_changed", self, "destroy")
		else:
			if get("holdTimer"):
				holdTimer.stop()
				if not spin_attack:
					destroy(null)
			else:
				destroy(null)

func _on_HoldTimer_timeout():
	spin_attack = true

func cut():
	for body in $Hitbox.get_overlapping_bodies():
		if body is TileMap && (body.name == "tall_grass" || body.name == "bush"):
			var tile = body.world_to_map($Hitbox.global_position)
			if body.get_cellv(tile) == -1:
				return
			body.set_cellv(tile, -1)
			body.update_bitmask_region()
			var grass_cut = preload("res://effects/grass_cut.tscn").instance()
			network.current_map.add_child(grass_cut)
			grass_cut.global_position = body.map_to_world(tile) + Vector2(8,6)



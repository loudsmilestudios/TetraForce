extends Weapon

onready var anim = $AnimationPlayer

const SPIN_HOLD_LENGTH = 0.75
var hold_time = 0
var spin_attack = false
var spin_multiplier = 2

func start():
	$Hitbox.connect("body_entered", self, "body_entered")
	$Hitbox.connect("area_entered", self, "area_entered")
	if is_network_master():
		anim.connect("animation_finished", self, "swing_ended")
		if get_parent().has_method("state_swing"):
			get_parent().state = "swing"
	anim.play(str("swing", get_parent().spritedir))
	#sfx.play("sword0")
	sfx.play(str("sword", randi() % 4))

func swing_ended(animation):
	anim.disconnect("animation_finished", self, "swing_ended")
	if input != null && Input.is_action_pressed(input): # if still holding sword button
		set_physics_process(true)
		delete_on_hit = true
		network.peer_call(self, "set_pos", [position])
	else:
		network.peer_call(self, "delete")
		delete()

func _physics_process(delta):
	if get_parent().has_method("state_hold") && !spin_attack:
		get_parent().state = "hold"
	
	if hold_time < SPIN_HOLD_LENGTH:
		hold_time += delta
	elif !spin_attack:
		sfx.play("swordcharge")
		ready_spin_attack()
	
	if get_parent().health <= 0 || get_parent().hitstun > 0 && !anim.assigned_animation.begins_with("spin"):
		network.peer_call(self, "delete")
		delete()
	
	if get_parent().get("push_counter") >= 0.25:
		if cut():
			network.peer_call(self, "delete")
			delete()
	
	if !Input.is_action_pressed(input): # on input release
		if spin_attack:
			if !anim.assigned_animation.begins_with("spin"):
				delete_on_hit = false
				if get_parent().has_method("state_spin"):
					get_parent().state = "spin"
				anim.connect("animation_finished", self, "end_spin_attack")
				spin_attack(get_parent().spritedir)
				network.peer_call(self, "spin_attack", [get_parent().spritedir])
		else:
			network.peer_call(self, "delete")
			delete()

func ready_spin_attack():
	spin_attack = true
	$Flash.play("flash")
	network.peer_call($Flash, "play", ["flash"])
	

func end_spin_attack(_a=null):
	delete()
	network.peer_call(self, "delete")

func spin_attack(dir):
	DAMAGE *= spin_multiplier
	$Flash.play("default")
	sfx.play("swordspin")
	anim.playback_speed = 8
	position = Vector2(0,0)
	anim.play(str("spin", dir))
	

func set_pos(p_pos):
	position = p_pos

func delete():
	get_parent().state = "default"
	get_parent().sprite.scale = Vector2(1,1)
	queue_free()

func body_entered(body):
	if body.has_method("cut") && get_parent().state != "hold":
		cut()
	if body is Entity && body != get_parent():
		damage(body)

func area_entered(area):
	if area is Collectable:
		area._collect(get_parent())

func cut():
	if is_network_master():
		for body in $Hitbox.get_overlapping_bodies():
			if body.has_method("cut"):
				body.cut($CutNode)
				return true
		return false
	return false

extends BossController

export(String) var location = "room"
export(String) var spawned_by = ""

onready var detect = $dead_captain/PlayerDetect
onready var anim = $dead_captain/AnimationPlayer

var deadcap
var target_direction

enum Stages {
	INACTIVE = 0,
	INTRO,
	ATTACK,
	SWORD,
	BOMB,
	VULNERABLE,
	ESCAPE,
	DEATH
}

func _ready():
	self.connect("entity_killed", self, "on_entity_killed")
	self.connect("stage_changed", self, "stage_change")
	deadcap = self.managed_entities[0]
	for entity in self.managed_entities:
		entity.spawned_by = self.spawned_by
		entity.check_spawn()
		entity.map.get_node(self.spawned_by).connect("reset", self, "is_dead")
		entity.map.get_node(spawned_by).connect("started", self, "spawned")
		entity.map.get_node(spawned_by).connect("started", self, "set_stage_intro")
	is_dead()

	
func _physics_process(delta):
	if !network.is_map_host():
		return

	for entity in self.managed_entities:
		entity.loop_movement()
		entity.loop_damage()
		if entity && entity.zone:
			if entity.zone.get_players() == []:
				self.set_stage(Stages.INACTIVE)

	match self.current_stage:
		Stages.INACTIVE:
			pass
			
		Stages.INTRO:
			for entity in self.managed_entities:
				entity.IS_VULNERABLE = false
			if not anim.current_animation in ["intro", "bomb"]:
				self.set_stage(Stages.ATTACK)
		
		Stages.ATTACK:
			var sees_player
			for body in detect.get_overlapping_bodies():
				if body is Player:
					sees_player = true
			if sees_player:
				self.set_stage(Stages.SWORD)
				
			else:
				self.set_stage(Stages.BOMB)
		
		Stages.SWORD:
			if not anim.current_animation in ["sword"]:
				self.set_stage(Stages.VULNERABLE)
			
		Stages.BOMB:
			if not anim.current_animation in ["bomb"]:
				self.set_stage(Stages.ESCAPE)
			
		Stages.VULNERABLE:
			for entity in self.managed_entities:
				entity.IS_VULNERABLE = true
			if not anim.current_animation in ["vulnerable", "break_free"]:
				self.set_stage(Stages.ESCAPE)
			
		Stages.ESCAPE:
			for entity in self.managed_entities:
				entity.IS_VULNERABLE = false
			yield(get_tree().create_timer(0.3), "timeout")
			jump_movement()
			if not anim.current_animation in ["vulnerable", "break_free", "bomb", "sword", "jump"]:
				self.set_stage(Stages.ATTACK)
				
		Stages.DEATH:
			is_dead()

func set_stage_intro():
	self.set_stage(Stages.INTRO)
	sfx.set_music("dungeon", "default")

func on_entity_killed(killer, entity):
	self.set_stage(Stages.DEATH)
	sfx.set_music("shrine", "default")
	
func stage_change(new_stage):
		match new_stage:
			Stages.INTRO:
				anim.play("intro")
				network.peer_call(anim, "play", ["intro"])
			Stages.SWORD:
				anim.play("sword")
				network.peer_call(anim, "play", ["sword"])
			Stages.BOMB:
				anim.play("bomb")
				network.peer_call(anim, "play", ["bomb"])
			Stages.VULNERABLE:
				anim.play("vulnerable")
				network.peer_call(anim, "play", ["vulnerable"])
			Stages.ESCAPE:
				anim.play("jump")
				network.peer_call(anim, "play", ["jump"])
			Stages.DEATH:
				pass
	
func boom_sfx():
	sfx.play("boom")
	
func fall_sfx():
	sfx.play("fall3")
	
func swordspin_sfx():
	sfx.play("swordspin")
	
func bomb_barrage():
	for i in range(5):
		var random_range = 64.0
		var random_vector = Vector2(rand_range(-random_range, random_range), rand_range(-random_range, random_range))
		deadcap.use_weapon("Bomb_Barrage", null, {"location":random_vector})
		network.peer_call(deadcap, "use_weapon", ["Bomb_Barrage", null, {"location":random_vector}])
	sfx.play("fall3")
		
func sword_strike():
	deadcap.use_weapon("Hurt_Extension")
	network.peer_call(deadcap, "use_weapon", ["Hurt_Extension"])
		
func jump_movement():
	if deadcap.zone && deadcap.zone.get_players() != []:
		var shortest_distance = 999999
		var closest_player = null
		for player in deadcap.zone.get_players():
			if deadcap.global_position.distance_to(player.global_position) < shortest_distance:
				shortest_distance = deadcap.global_position.distance_to(player.global_position)
				closest_player = player
		target_direction = closest_player.global_position - deadcap.global_position
		set_move_direction(target_direction)
		network.peer_call(self, "set_move_direction", [target_direction])
			
func set_move_direction(move):
	deadcap.movedir = move * deadcap.SPEED
	for entity in self.managed_entities:
		if anim.current_animation in ["jump",]:
			entity.hitbox.monitorable = false
			entity.set_collision_mask_bit(10,0)
			entity.set_collision_mask_bit(1,0)
		else:
			entity.movedir = Vector2.ZERO
			entity.hitbox.monitorable = true
			yield(get_tree().create_timer(0.1), "timeout")
			entity.set_collision_mask_bit(10,1)
			entity.set_collision_mask_bit(1,1)
	
#// Functions called to allow Boss Controller Compatability
	
func is_dead():
	for entity in self.managed_entities:
		entity.hitbox.monitorable = false
		entity.set_collision_mask_bit(1,0)
		entity.set_collision_mask_bit(10,0)
		
func spawned():
	for entity in self.managed_entities:
		entity.hitbox.monitorable = true
		entity.set_collision_mask_bit(1,1)
		entity.set_collision_mask_bit(10,1)
		
	

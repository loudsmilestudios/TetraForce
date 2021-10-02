extends BossController

func _ready():
	# Boss logic should only run on map host
	# for others this logic should be disabled
	if !network.is_map_host():
		set_physics_process(false)
		return
	
	# You can access entities associated with
	# the boss with `self.managed_entities`
	for entity in self.managed_entities:
		print(entity)
	
	# Here are a few signals that you can utilize
	# the associated functions are for debug only
	self.connect("all_entities_killed", self, "on_all_entities_killed")
	self.connect("entity_killed", self, "on_entity_killed")
	self.connect("entity_damaged", self, "on_entity_damaged")
	self.connect("stage_changed", self, "on_stage_changed")
	
	_boss_ready() # This is for sample boss logic

func on_all_entities_killed(last_killer):
	print("All entities killed by %s" % last_killer.name)

func on_entity_killed(killer, entity):
	print("Entity %s killed by %s" % [entity.name, killer.name])

func on_entity_damaged(damager, entity):
	print("Entity %s damaged by %s" % [entity.name, damager.name])

func on_stage_changed(new_stage):
	print("Changed to stage: %s" % new_stage)




#===================#
# SAMPLE BOSS LOGIC #
#===================#
# This section actually has the implementation
# of the boss to use as a pratical example

# This enum is made to give a developer
# friendly name to the numbers associated
# with stages
enum Stages {
	INACTIVE = 0,
	VULNERABLE = 2
}

# This is just _ready() but called here to
# seperate from reference
func _boss_ready():
	# Connecting signals for sample boss logic
	self.connect("all_entities_killed", self, "boss_defeated")
	self.connect("entity_damaged", self, "on_boss_damaged")
	self.connect("entity_killed", self, "clean_up_entity")

func _physics_process(delta):
	match self.current_stage:
		Stages.INACTIVE:
			# INACTIVE state has all logic disabled and heals entities
			for entity in self.managed_entities:
				entity.set_physics_process(false)
				network.peer_call(entity, "set_physics_process", false)
				entity.set_health(entity.MAX_HEALTH)
				network.peer_call(entity, "set_health", entity.MAX_HEALTH)
		Stages.VULNERABLE:
			# VULNERABLE state enables all logic
			for entity in self.managed_entities:
				entity.set_physics_process(true)
				network.peer_call(entity, "set_physics_process", true)

func clean_up_entity(killer, entity):
	yield(get_tree().create_timer(0.4), "timeout")
	entity.queue_free()

# When hit while inactive, become vulnerable
func on_boss_damaged(damager, entity):
	match current_stage:
		Stages.INACTIVE:
			set_stage(Stages.VULNERABLE)

# When all entities are killed, destroy self!
func boss_defeated(last_killer):
	print("Yay boss defeated!")
	#network.peer_call(self, "queue_free")
	#self.queue_free()

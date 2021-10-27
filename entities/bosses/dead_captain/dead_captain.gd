extends BossController

var radius

enum Stages {
	INACTIVE = 0,
	ATTACK,
	SWORD,
	BOMB,
	VULNERABLE,
	ESCAPE,
	DEATH
}

func _ready():
	self.connect("entity_killed", self, "on_entity_killed")
	
	
func _physics_process(delta):
	if !network.is_map_host():
		return
		
	for entity in self.managed_entities:
		entity.loop_movement()
		entity.loop_damage()
		entity.IS_VULNERABLE = true

	match self.current_stage:
		Stages.INACTIVE:
			self.set_stage(Stages.ATTACK)
		Stages.ATTACK:
			if radius == true:
				self.set_stage(Stages.SWORD)
			else:
				self.set_stage(Stages.BOMB)
		Stages.SWORD:
			self.set_stage(Stages.VULNERABLE)
		Stages.BOMB:
			self.set_stage(Stages.ESCAPE)
		Stages.VULNERABLE:
			self.set_stage(Stages.ESCAPE)
		Stages.ESCAPE:
			self.set_stage(Stages.ATTACK)
		Stages.DEATH:
			pass

func on_entity_killed(killer, entity):
	self.set_stage(Stages.DEATH)

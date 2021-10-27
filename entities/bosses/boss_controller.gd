class_name BossController
extends Node2D

enum DefaultStage { INACTIVE = 0 }

signal all_entities_killed(last_killer)
signal entity_killed(killer, entity)
signal entity_damaged(damager, entity)
signal stage_changed(new_stage)

export(Array, NodePath) var _managed_entities = [] # Only utilized on start
export(int) var current_stage = DefaultStage.INACTIVE setget set_stage, get_stage
export(bool) var automatic_boss_bar = true

var difficulty_scale setget ,get_difficulty_scale
var managed_entities = [] # Contains all entities managed by controller

onready var boss_overlay : BossOverlay

func _ready():
	_load_entities()

func _process(delta):
	if _network_is_map_host():
		if automatic_boss_bar:
			_boss_bar_auto_init()
	set_process(false)

func _network_is_map_host():
	return network.is_map_host()

# _load_entities: Loads all NodePath in _managed_entities,
#		configures it and places it the managed_entities Array
func _load_entities():
	for entity_path in _managed_entities:
		var entity = get_node(entity_path)
		if entity is Entity:
			if not entity in managed_entities:
				_configure_entity(entity)
		else:
			printerr("BossController %s: '%s' is not an Entity!"
				% [name, entity.name])

# _configure_entity: Takes in an entity, adds it to an array, and
#		setup entity signals
func _configure_entity(entity : Entity):
	managed_entities.append(entity)
	entity.connect("damaged", self, "_on_entity_damaged", [entity])
	entity.connect("killed", self, "_on_entity_killed", [entity])


# _error_if_not_host: Prints error & returns true if not
#		map host
func _error_if_not_host():
	if !network.is_map_host():
		printerr("Cannot call BossController logic if not map host!")
		return true
	return false

#=================#
# Signal Handlers #
#=================#
func _on_entity_damaged(damager, entity):
	emit_signal("entity_damaged", damager, entity)
	if automatic_boss_bar:
		_boss_bar_auto_update()

func _on_entity_killed(killer, entity):
	emit_signal("entity_killed", killer, entity)
	managed_entities.erase(entity)
	if len(managed_entities) <= 0:
		emit_signal("all_entities_killed", killer)

#===================#
# Getters & Setters #
#===================#

# For: `current_stage`
func set_stage(new_stage):
	if _error_if_not_host(): return
	if new_stage != current_stage:
		current_stage = new_stage
		emit_signal("stage_changed", current_stage)

func get_stage():
	if _error_if_not_host(): return
	return current_stage

# For: `difficulty_scale`
func get_difficulty_scale():
	return 1

#================#
# Boss Bar Logic #
#================#

# _boss_bar_verify_overlay: Returns true if boss_overlay is gettable
func _boss_bar_verify_overlay() -> bool:
	if not boss_overlay:
		boss_overlay = global.player.hud.boss_overlay
	
	if boss_overlay:
		return true
	
	printerr("Boss bar does not exist!")
	return false

# boss_bar_show: Makes the boss bar visible
func boss_bar_show():
	if _error_if_not_host(): return
	if _boss_bar_error_if_in_automatic(): return
	_boss_bar_show()

# boss_bar_hide: Makes the boss bar no longer visible
func boss_bar_hide():
	if _error_if_not_host(): return
	if _boss_bar_error_if_in_automatic(): return
	_boss_bar_hide()

# boss_bar_set_max_hp: Sets the max_hp value on the boss bar
func boss_bar_set_max_hp(max_hp):
	if _error_if_not_host(): return
	if _boss_bar_error_if_in_automatic(): return
	_boss_bar_set_max_hp(max_hp)
	network.peer_call(self, "_boss_bar_set_max_hp", max_hp)

# boss_bar_set_current_hp: Sets the current_hp value on the boss bar
func boss_bar_set_current_hp(current_hp):
	if _error_if_not_host(): return
	if _boss_bar_error_if_in_automatic(): return
	_boss_bar_set_current_hp(current_hp)
	network.peer_call(self, "_boss_bar_set_current_hp", current_hp)

# _boss_bar_error_if_in_automatic: Prints error & returns true if
#		boss bar is in automatic mode
func _boss_bar_error_if_in_automatic():
	if automatic_boss_bar:
		printerr("Cannot update BossBar associated with '%s', it is in automatic mode!" % self.name)
		return true
	return false

# _boss_bar_auto_update: Calculates max hp, sets max hp, and calls update
func _boss_bar_auto_init():
	var max_hp = _boss_bar_auto_calculate_max_hp()
	_boss_bar_set_max_hp(max_hp)
	network.peer_call(self, "_boss_bar_set_max_hp", max_hp)
	_boss_bar_auto_update()
	self.connect("stage_changed", self, "_boss_bar_on_stage_changed")

func _boss_bar_on_stage_changed(new_stage):
	if automatic_boss_bar and new_stage != DefaultStage.INACTIVE:
		_boss_bar_show()

# _boss_bar_auto_update: Calculates and sets boss bar values
func _boss_bar_auto_update():
	var current_hp = _boss_bar_auto_calculate_current_hp()
	_boss_bar_set_current_hp(current_hp)
	network.peer_call(self, "_boss_bar_set_current_hp", current_hp)

# _boss_bar_auto_calculate_max_hp: Calculates max_hp of all entities
func _boss_bar_auto_calculate_max_hp():
	var max_hp = 0
	for entity in managed_entities:
		max_hp += entity.MAX_HEALTH
	return max_hp

# _boss_bar_auto_calculate_current_hp: Calculates health of all entities
func _boss_bar_auto_calculate_current_hp():
	var current_hp = 0
	for entity in managed_entities:
		current_hp += entity.health
	return current_hp

# _boss_bar_set_max_hp: Sends message to Boss Bar UI to update max
func _boss_bar_set_max_hp(max_hp):
	if _boss_bar_verify_overlay():
		boss_overlay.set_max_boss_hp(max_hp)

# _boss_bar_set_max_hp: Sends message to Boss Bar UI to update current
func _boss_bar_set_current_hp(new_hp):
	if _boss_bar_verify_overlay():
		boss_overlay.set_current_boss_hp(new_hp)
		# Hide boss bar
		if automatic_boss_bar and new_hp <= 0:
			boss_bar_hide()

# _boss_bar_show: Sends message to Boss Bar UI display the bar on screen
func _boss_bar_show():
	if _boss_bar_verify_overlay():
		boss_overlay.show_boss_bar()

# _boss_bar_hide: Sends message to hide the Boss Bar UI
func _boss_bar_hide():
	if _boss_bar_verify_overlay():
		boss_overlay.hide_boss_bar()

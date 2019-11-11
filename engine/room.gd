extends Node

class_name Room
	
#var map 
var tile_rect = Rect2(0, 0, 16, 9)
var entities = []
var enemies = {}
var players = {}

signal player_entered()
signal first_player_entered()
signal player_exited()
signal last_player_exited()
signal enemies_defeated()
signal empty()

func add_entity(entity):
	entities.append(entity)
	
	if entity.get("TYPE") == "ENEMY":
		enemies[entity.get_instance_id()] = true
	
	if entity.get("TYPE") == "PLAYER":
		if players.size() == 0:
			emit_signal("first_player_entered")
		players[entity.get_instance_id()] = true
		emit_signal("player_entered")

func remove_entity(entity):
	entities.erase(entity)
	
	if entity.get("TYPE") == "ENEMY":
		enemies.erase(entity.get_instance_id())
		
		if enemies.empty():
			emit_signal("enemies_defeated")
	
	if entity.get("TYPE") == "PLAYER":
		players.erase(entity.get_instance_id())
		if players.size() == 0:
			emit_signal("last_player_exited")
		emit_signal("player_exited")
	
	if entities.empty():
		emit_signal("empty")

tool
extends StaticBody2D

export var is_blasted = false
export var patchdirection = ""
var tiles_to_patch
var all_set
var parent 

func _ready() -> void:
	#Set up patch dictionary and globals
	tiles_to_patch = {"left": -1, "right" : -1, "up" : -1, "down" : -1}
	is_blasted = false
	visible = true
	all_set = false
	parent = get_parent()
	
	#set up collision and physics
	set_physics_process(true)
	set_collision_layer_bit(0,1)
	set_collision_layer_bit(1,1)

func _physics_process(delta):
	if !all_set:
		if parent != null:
			#Find current tile in teh tilemap
			var wall_tilemap = parent.get_node("walls")
			var tile_pos = wall_tilemap.world_to_map(position)
			var this_tile = wall_tilemap.get_cellv(tile_pos)
			
			#Work out directions to patch and save them to a
			#dictionary for later.
			if ("l" in patchdirection):
				var left_tile = Vector2(tile_pos.x - 1, tile_pos.y)
				tiles_to_patch["left"] = wall_tilemap.get_cellv(left_tile)
				wall_tilemap.set_cellv(left_tile, this_tile)
				
			if ("r" in patchdirection):
				var right_tile = Vector2(tile_pos.x + 1, tile_pos.y)
				tiles_to_patch["right"] = wall_tilemap.get_cellv(right_tile)
				wall_tilemap.set_cellv(right_tile, this_tile)
			
			if ("u" in patchdirection):
				var up_tile = Vector2(tile_pos.x, tile_pos.y - 1)
				tiles_to_patch["up"] = wall_tilemap.get_cellv(up_tile)
				wall_tilemap.set_cellv(up_tile, this_tile)
				
			if ("d" in patchdirection):
				var down_tile = Vector2(tile_pos.x, tile_pos.y + 1)
				tiles_to_patch["down"] = wall_tilemap.get_cellv(down_tile)
				wall_tilemap.set_cellv(down_tile, this_tile)
				
			#We only want to do this once.
			all_set = true
	
func blast():
	#set flags
	is_blasted = true
	visible = false
	set_collision_layer_bit(0,0)
	set_collision_layer_bit(1,0)
	
	#find tilemap
	var wall_tilemap = parent.get_node("walls")
	var tile_pos = wall_tilemap.world_to_map(position)
	
	#hide the broken wall
	wall_tilemap.set_cellv(tile_pos, -1)
	
	#overwrite saved wall tiles from the dictionary we set up earlier.
	if ("l" in patchdirection):
		var left_tile = Vector2(tile_pos.x - 1, tile_pos.y)
		wall_tilemap.set_cellv(left_tile, tiles_to_patch["left"] )
		
	if ("r" in patchdirection):
		var right_tile = Vector2(tile_pos.x + 1, tile_pos.y)
		wall_tilemap.set_cellv(right_tile, tiles_to_patch["right"])
	
	if ("u" in patchdirection):
		var up_tile = Vector2(tile_pos.x, tile_pos.y - 1)
		wall_tilemap.set_cellv(up_tile, tiles_to_patch["up"] )
		
	if ("d" in patchdirection):
		var down_tile = Vector2(tile_pos.x , tile_pos.y + 1)
		wall_tilemap.set_cellv(down_tile, tiles_to_patch["down"])
	

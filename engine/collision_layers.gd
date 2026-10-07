extends RefCounted
class_name CollisionLayers

# Layer membership describes who can detect an object; the detector/mover's
# mask decides what it sees. Godot 4 character motion does NOT also consult
# the other body's mask, unlike Godot 3 KinematicBody2D motion.
const WORLD = 1 << 0
const ACTOR = 1 << 1
const PROJECTILE = 1 << 2
# ACTOR is shared by players, enemies, and enemy-blocking scenery. This
# separate membership lets players collide with enemies without colliding
# with other players (the Godot 3 behavior).
const ENEMY_BODY = 1 << 3
const WALKFX = 1 << 5
const WATER = 1 << 6
const HOLES = 1 << 7
const ZONE = 1 << 10
const TERRAIN = 1 << 31

static func configure_tiles(layer: TileMapLayer, membership: int, mask: int) -> void:
	if !layer.tile_set:
		return
	# Imported layers may share a TileSet. Changing water/grass/holes must
	# never change the neighboring ordinary wall layer's physics settings.
	layer.tile_set = layer.tile_set.duplicate()
	for index in layer.tile_set.get_physics_layers_count():
		layer.tile_set.set_physics_layer_collision_layer(index, membership)
		layer.tile_set.set_physics_layer_collision_mask(index, mask)

extends TileMapLayer

var walkfx_texture = preload("res://effects/walkfx_shallow.png")

func _ready():
	CollisionLayers.configure_tiles(self, CollisionLayers.TERRAIN | CollisionLayers.WALKFX, CollisionLayers.WALKFX)
	add_to_group("fxtile")

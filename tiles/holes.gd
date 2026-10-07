extends TileMapLayer

class_name Holes

func _ready():
	CollisionLayers.configure_tiles(self, CollisionLayers.HOLES, CollisionLayers.HOLES)

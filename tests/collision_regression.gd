extends Node

# Run with: godot --headless --path . res://tests/collision_regression.tscn
# Baseline: e48e2f3 (Godot 3). Movement previously accepted either side's
# layer/mask pair. These tests check behavior, including non-colliding pairs,
# rather than asserting that migrated bitfields equal the old bitfields.
const ENEMIES = [
	"bat", "cucukin", "knawblin", "pirafaux", "slime", "smashroom",
	"sneaky_bush", "stalfos", "thief_cat", "turtle",
]
const OBSTACLES = [
	["tiles/block", 1025, 3], ["tiles/statue", 1025, 3],
	["tiles/gravestone", 1, 3], ["tiles/floating_barrel", 1025, 3],
	["tiles/pot", 3, 3], ["tiles/chest", 1, 3],
	["tiles/block_door", 1, 3], ["tiles/enemy_door", 1, 3],
	["tiles/key_door", 1, 3], ["tiles/lockblock", 1, 3],
	["tiles/bombable_rock", 1, 3], ["tiles/bombable_door", 1, 3],
	["tiles/brazier", 1, 3], ["tiles/blue_cannon", 1, 3],
	["tiles/red_cannon", 1, 3], ["tiles/cannonwall", 1, 2147483651],
	["tiles/thorn_wall", 1, 3], ["entities/npcs/npc", 1, 3],
	["tiles/sign", 1, 1], ["tiles/reset_wheel", 1025, 1025],
	["tiles/enemy_door_trigger", 1025, 1025],
]
const DIRECTIONS = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

class TestMap extends Node2D:
	signal player_entered(id)
	var music = ""
	var musicfx = ""
	var light = "default"
	func is_game():
		return true
	func spawn_collectable(_kind, _position, _chance):
		pass

var failures := 0
var checks := 0
var map: TestMap

func _ready():
	network.initialize()
	map = TestMap.new()
	map.name = "CollisionTestMap"
	add_child(map)
	network.current_map = map
	network.map_hosts[map.name] = network.pid
	var player = load("res://entities/player/player.tscn").instantiate()
	add_mover(player)
	var movers: Array[Entity] = [player]
	for enemy_name in ENEMIES:
		var path = "res://entities/enemies/%s/%s.tscn" % [enemy_name, enemy_name]
		var enemy = load(path).instantiate()
		add_mover(enemy)
		movers.append(enemy)
	await physics_update()
	await test_enemy_walk_effects(movers)

	for entry in OBSTACLES:
		var obstacle = load("res://%s.tscn" % entry[0]).instantiate()
		# Doors need dungeon switches; test their real body/shape resources
		# without running unrelated puzzle/dialogue setup in this empty map.
		strip_scripts(obstacle)
		map.add_child(obstacle)
		obstacle.position = Vector2.ZERO
		if entry[0] == "tiles/block_door":
			obstacle.get_node("AnimationPlayer").play("locked_up")
			obstacle.get_node("AnimationPlayer").advance(0)
		elif entry[0] == "tiles/enemy_door":
			obstacle.get_node("AnimationPlayer").play("enemy_locked_up")
			obstacle.get_node("AnimationPlayer").advance(0)
		await physics_update()
		for mover in movers:
			var old_layer = 1090 if mover is Player else 1154
			var old_mask = 1 if mover is Player else 130
			var expected = (old_mask & entry[1]) != 0 or (old_layer & entry[2]) != 0
			for direction in DIRECTIONS:
				var from = Transform2D(0.0, -direction * 48.0)
				var blocked = mover.test_move(from, direction * 96.0)
				check(blocked == expected, "%s vs %s moving %s: blocked=%s expected=%s" % [mover.name, entry[0], direction, blocked, expected])
		if entry[0] in ["tiles/block_door", "tiles/enemy_door"]:
			var animation_name = "unlocked_up" if entry[0] == "tiles/block_door" else "enemy_unlocked_up"
			obstacle.get_node("AnimationPlayer").play(animation_name)
			obstacle.get_node("AnimationPlayer").advance(0)
			await physics_update()
			for mover in movers:
				check(!mover.test_move(Transform2D(0.0, Vector2(-48, 0)), Vector2(96, 0)), "%s must pass an open %s" % [mover.name, entry[0]])
		obstacle.free()

	await test_actor_contacts(player, movers)
	await test_terrain(player, movers)
	await test_bushes(player, movers)
	await test_dormant_enemy(movers[9])
	await test_pushing(player, movers[6])
	await test_pickups(player, movers[6])
	await test_projectiles()

	for mover in movers:
		mover.queue_free()
	await get_tree().process_frame
	await test_imported_maps("res://maps")
	network.complete()
	await get_tree().process_frame
	check(multiplayer.multiplayer_peer is OfflineMultiplayerPeer, "Teardown must restore offline authority")
	sfx.stop_all()
	await get_tree().create_timer(0.1).timeout
	print("Collision regression: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func add_mover(mover: Entity):
	mover.position = Vector2(10000 + checks * 100, 10000)
	map.add_child(mover)
	mover.set_process(false)
	mover.set_physics_process(false)
	check(mover.motion_mode == CharacterBody2D.MOTION_MODE_FLOATING, "%s must use floating motion" % mover.name)

func strip_scripts(node: Node):
	node.set_script(null)
	for child in node.get_children():
		strip_scripts(child)

func physics_update():
	await get_tree().physics_frame
	await get_tree().physics_frame

func check(condition: bool, message: String):
	checks += 1
	if !condition:
		failures += 1
		push_error(message)

func test_enemy_walk_effects(movers: Array[Entity]):
	for enemy in movers.slice(1):
		check(!enemy.walkfx.visible, "%s must start without a stray grass sprite" % enemy.name)
		enemy.walkfx.show()
		enemy._process(0.0)
		check(!enemy.walkfx.visible, "%s must hide walk effects on bare ground" % enemy.name)

	var grass = make_tile_layer("res://tiles/tall_grass.gd")
	grass.set_meta("replace", "res://tiles/tall_grass.tscn")
	map.add_child(grass)
	var bat = movers[1]
	var mushroom = movers[6]
	var bat_position = bat.position
	var mushroom_position = mushroom.position
	# Entity's ground sensor is six pixels below its root.
	bat.position = Vector2(8, 2)
	mushroom.position = Vector2(8, 2)
	await physics_update()
	mushroom._process(0.0)
	check(mushroom.walkfx.visible, "Ground enemies must still disturb grass")

	bat.anim.play("sees_player")
	bat.anim.advance(0.0)
	bat._process(0.0)
	check(bat.get_node("Shadow").visible, "Flying bat must show its animated shadow")
	check(bat.get_node("Shadow/Sprite2D").texture.resource_path == "res://effects/shadow.png", "Bat shadow must retain the shadow texture")
	check(!bat.walkfx.visible, "Flying bat must not show grass over its shadow")

	bat.anim.play("land")
	bat.anim.advance(0.31)
	bat._process(0.0)
	check(!bat.get_node("Shadow").visible, "Landed bat must hide the flight shadow")
	check(bat.walkfx.visible, "Landed bat may show the ground's grass effect")

	bat.position = bat_position
	mushroom.position = mushroom_position
	grass.free()
	await physics_update()
	bat._process(0.0)
	mushroom._process(0.0)
	check(!bat.walkfx.visible and !mushroom.walkfx.visible, "Walk effects must clear after leaving grass")

func test_actor_contacts(player: Player, movers: Array[Entity]):
	var other_player = load("res://entities/player/player.tscn").instantiate()
	add_mover(other_player)
	other_player.position = Vector2.ZERO
	await physics_update()
	check(!player.test_move(Transform2D(0.0, Vector2(-48, 0)), Vector2(96, 0)), "Players must not physically block other players")
	for enemy in movers.slice(1):
		check(enemy.test_move(Transform2D(0.0, Vector2(-48, 0)), Vector2(96, 0)), "Enemies must collide with a player")
	other_player.free()
	for enemy in movers.slice(1):
		var saved = enemy.position
		enemy.position = Vector2.ZERO
		await physics_update()
		check(player.test_move(Transform2D(0.0, Vector2(-48, 0)), Vector2(96, 0)), "Player must collide with %s" % enemy.name)
		enemy.position = saved

func make_tile_layer(script_path: String) -> TileMapLayer:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(16, 16)
	tileset.add_physics_layer()
	tileset.add_physics_layer()
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://tiles/block.png")
	atlas.texture_region_size = Vector2i(16, 16)
	tileset.add_source(atlas, 0)
	atlas.create_tile(Vector2i.ZERO)
	var data := atlas.get_tile_data(Vector2i.ZERO, 0)
	for index in 2:
		data.add_collision_polygon(index)
		data.set_collision_polygon_points(index, 0, PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]))
	var layer := TileMapLayer.new()
	layer.tile_set = tileset
	layer.set_cell(Vector2i.ZERO, 0, Vector2i.ZERO)
	if !script_path.is_empty():
		layer.set_script(load(script_path))
	return layer

func test_terrain(player: Player, movers: Array[Entity]):
	for script_path in ["water", "holes", "shallow", "tall_grass", "wheat"]:
		var layer = make_tile_layer("res://tiles/%s.gd" % script_path)
		if script_path == "tall_grass":
			layer.set_meta("replace", "res://tiles/tall_grass.tscn")
		# Retain an alias to catch accidental changes to other map layers.
		var original_tileset: TileSet = layer.tile_set
		map.add_child(layer)
		await physics_update()
		check(original_tileset.get_physics_layer_collision_layer(0) == 1, "%s must not mutate a shared TileSet" % script_path)
		for mover in movers:
			var expected = false
			if script_path == "water":
				expected = true
			elif script_path == "holes":
				expected = mover is Enemy
			elif script_path == "shallow":
				expected = mover.name in ["smashroom", "Pirafaux", "Stalfos"]
			var from := Transform2D(0.0, Vector2(-48, 8))
			check(mover.test_move(from, Vector2(96, 0)) == expected, "%s vs %s terrain" % [mover.name, script_path])
		if script_path == "water":
			player.state_swim()
			check(!player.test_move(Transform2D(0.0, Vector2(-48, 8)), Vector2(96, 0)), "Swimming must remove only water blocking")
			check(player.get_collision_mask_value(1), "Swimmers must still collide with walls")
			check(player.get_collision_mask_value(4), "Swimmers must still collide with enemies")
			check(player.get_collision_layer_value(11), "Swimmers must remain discoverable by room zones")
			player.set_collision_mask_value(7, true)
		if script_path == "holes":
			var enemy: Enemy = movers[6]
			enemy.set_hole_bit(false)
			check(!enemy.test_move(Transform2D(0.0, Vector2(-48, 8)), Vector2(96, 0)), "Knockback must allow enemies to enter holes")
			enemy.set_hole_bit(true)
		for index in 2:
			check(layer.tile_set.get_physics_layer_collision_layer(index) == layer.tile_set.get_physics_layer_collision_layer(0), "All TileSet physics layers need the terrain contract")
		layer.free()

func test_bushes(player: Player, movers: Array[Entity]):
	# A script-only bush layer kept map collision in the Godot 3 importer;
	# it must not inherit the walkable replacement grass contract.
	var bushes = make_tile_layer("res://tiles/tall_grass.gd")
	map.add_child(bushes)
	await physics_update()
	for mover in movers:
		check(mover.test_move(Transform2D(0.0, Vector2(-48, 8)), Vector2(96, 0)), "%s must not walk through uncut bushes" % mover.name)
	bushes.process_tile(Vector2i.ZERO)
	await physics_update()
	check(!player.test_move(Transform2D(0.0, Vector2(-48, 8)), Vector2(96, 0)), "Cut bushes must become passable")
	bushes.free()

func test_dormant_enemy(enemy: Enemy):
	var shapes = enemy.find_children("*", "CollisionPolygon2D", true, false)
	check(!shapes.is_empty(), "Dormancy test needs an enemy with a polygon detector")
	enemy.set_dead()
	await physics_update()
	for shape in enemy.find_children("*", "", true, false):
		if shape is CollisionShape2D or shape is CollisionPolygon2D:
			check(shape.disabled, "Dormant enemy must disable %s" % shape.name)
	enemy.spawned()
	enemy.set_physics_process(false)
	await physics_update()
	for shape in enemy.find_children("*", "", true, false):
		if shape is CollisionShape2D or shape is CollisionPolygon2D:
			check(!shape.disabled, "Spawned enemy must restore %s" % shape.name)
	enemy.position = Vector2(20000, 20000)

class TestHud extends Node:
	func hide_action():
		pass
	func show_action():
		pass
	func update_hearts():
		pass
	func update_weapons():
		pass
	func update_tetrans():
		pass

func test_pushing(player: Player, enemy: Enemy):
	player.hud = TestHud.new()
	player.add_child(player.hud)
	player.ray.add_exception(player.hitbox)
	player.ray.add_exception(player.center)
	player.ray.add_exception(player.get_node("ZoneHandler"))
	for direction in DIRECTIONS:
		var block = load("res://tiles/block.tscn").instantiate()
		block.position = Vector2(8, 8)
		map.add_child(block)
		player.position = block.position - direction * 32
		player.movedir = direction
		await physics_update()
		for index in 30:
			player.loop_movement()
			await get_tree().physics_frame
			if player.is_on_wall():
				break
		player.update_interaction_ray()
		check(player.is_on_wall(), "Player must register a wall when pushing %s" % direction)
		check(player.ray.get_collider() == block, "Interaction ray must hit the block when pushing %s" % direction)
		player.push_counter = 0.75
		player.loop_interact()
		await get_tree().create_timer(0.15).timeout
		check(block.pushed, "Block must start moving %s" % direction)
		check(block.target_position.is_equal_approx(Vector2(8, 8) + direction * 16), "Each push must move exactly one tile %s" % direction)
		player.last_movedir = Vector2(1, 1)
		check(player.get_push_direction() == direction, "Diagonal steering must not replace the cardinal push direction")
		block.interact(player)
		check(block.target_position.is_equal_approx(Vector2(8, 8) + direction * 16), "Changing player input must not redirect an active stone push")
		check(enemy.test_move(Transform2D(0.0, block.position - direction * 48), direction * 96), "Moving stone must still block mushrooms")
		var enemy_position = enemy.position
		enemy.position = block.position + direction * 48
		enemy.velocity = -direction * 6000
		enemy.move_and_slide()
		check(enemy.is_on_wall() and enemy.get_slide_collision_count() > 0 and enemy.get_slide_collision(0).get_collider() == block, "Mushroom movement must stop against the moving stone %s" % direction)
		enemy.position = enemy_position
		await block.tween.finished
		check(block.position.is_equal_approx(block.target_position), "Stone must finish its push at the destination")
		block.free()
		player.position = Vector2(30000, 30000)

func test_pickups(player: Player, enemy: Enemy):
	for item in ["arrow", "bomb", "heart", "tetran"]:
		var solid = load("res://tiles/block.tscn").instantiate()
		strip_scripts(solid)
		map.add_child(solid)
		var pickup = load("res://entities/collectables/%s.tscn" % item).instantiate()
		map.add_child(pickup)
		await get_tree().create_timer(0.85).timeout
		check(is_instance_valid(pickup) and !pickup.is_queued_for_deletion(), "%s pickup must ignore scenery on the actor layer" % item)
		solid.free()
		var enemy_position = enemy.position
		enemy.position = Vector2.ZERO
		await physics_update()
		check(is_instance_valid(pickup) and !pickup.is_queued_for_deletion(), "%s pickup must ignore enemies" % item)
		enemy.position = enemy_position
		player.position = Vector2.ZERO
		await physics_update()
		await get_tree().process_frame
		check(!is_instance_valid(pickup), "%s must be collected through body_entered by a player" % item)
		player.position = Vector2(30000, 30000)

class WeaponOwner extends Node2D:
	var TYPE = "ENEMY"
	var fired = true

func test_projectiles():
	var terrain = make_tile_layer("")
	CollisionLayers.configure_tiles(terrain, CollisionLayers.WORLD | CollisionLayers.ACTOR, 3)
	map.add_child(terrain)
	var shooter = WeaponOwner.new()
	map.add_child(shooter)
	await physics_update()
	for item in ["arrow", "bone", "rock", "spike", "cannonball"]:
		var projectile = load("res://entities/weapons/%s.tscn" % item).instantiate()
		shooter.add_child(projectile)
		projectile.shooter = shooter
		projectile.received_sync = true
		projectile.position = Vector2(8, 8)
		projectile.get_node("Hitbox").body_entered.connect(projectile.body_entered)
		await physics_update()
		await get_tree().process_frame
		check(!is_instance_valid(projectile), "%s must collide with a TileMapLayer through body_entered" % item)
	terrain.free()
	shooter.free()

func test_imported_maps(path: String):
	var directory := DirAccess.open(path)
	for child in directory.get_directories():
		await test_imported_maps(path.path_join(child))
	for file in directory.get_files():
		if file.get_extension() != "tmx":
			continue
		var level = load(path.path_join(file)).instantiate()
		# Keep all map collision and puzzle scripts active, while substituting
		# only the root's player-spawning/menu logic for the test map root.
		var imported_map := TestMap.new()
		imported_map.name = file.get_basename()
		imported_map.music = level.music
		imported_map.musicfx = level.musicfx
		imported_map.light = level.light
		for child in level.get_children():
			clear_owners(child)
			child.reparent(imported_map, false)
		level.free()
		network.current_map = imported_map
		network.map_hosts[imported_map.name] = network.pid
		add_child(imported_map)
		stop_simulation(imported_map)
		await physics_update()
		await physics_update()
		for node in imported_map.find_children("*", "", true, false):
			if node is PhysicsBody2D and node.z_index == RenderLayers.ACTORS:
				var sprite = node.get_node_or_null("Sprite2D")
				if sprite is Sprite2D and sprite.z_index == 0:
					check(sprite.z_as_relative, "%s: %s sprite must inherit the actor plane, not bypass it with absolute Z" % [file, node.name])
			if node.get("def") == "dungeon" or node.get_script() == load("res://tiles/key_door.gd") or node.get_script() == load("res://tiles/lockblock.gd"):
				check(imported_map.has_node("dungeon_handler"), "%s: dungeon rewards and locks require the named handler" % file)
			if node is Enemy:
				check(node.get_collision_layer_value(4), "%s: %s lacks enemy body membership" % [file, node.name])
			elif node is PhysicsBody2D and (node.collision_mask & (CollisionLayers.ACTOR | CollisionLayers.ZONE)):
				check(node.get_collision_layer_value(2), "%s: %s does not block enemy motion" % [file, node.name])
			if node.is_in_group("zoned"):
				check(is_instance_valid(node.zone), "%s: %s was not assigned to a room zone" % [file, node.name])
			# Replacement templates supplied collision on every occupied
			# tile. Script-only hole layers instead retain authored TSX
			# polygons, including deliberately non-colliding border graphics.
			if node is TileMapLayer and (node.has_meta("replace") or node.is_in_group("fxtile")):
				for cell in node.get_used_cells():
					var data = node.get_cell_tile_data(cell)
					check(data != null and data.get_collision_polygons_count(0) > 0, "%s: %s cell %s lost replacement collision geometry" % [file, node.name, cell])
					if node.has_meta("replace"):
						var replacement = str(node.get_meta("replace")).get_file().get_basename()
						check(data.terrain_set == 0 and data.terrain == 0, "%s: %s cell %s lost replacement terrain rules" % [file, node.name, cell])
						var source = node.tile_set.get_source(node.get_cell_source_id(cell)) as TileSetAtlasSource
						if replacement not in ["tall_grass", "wheat"]:
							check(source.get_tile_animation_frames_count(node.get_cell_atlas_coords(cell)) > 1, "%s: %s cell %s must animate in the imported map" % [file, node.name, cell])
			if node is CollisionShape2D:
				check_shape(node.shape, "%s/%s" % [file, node.name])
		imported_map.free()
		network.current_map = map
		print("Checked imported map: %s" % file)

func clear_owners(node: Node):
	node.owner = null
	for child in node.get_children():
		clear_owners(child)

func stop_simulation(node: Node):
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children():
		stop_simulation(child)

func check_shape(shape: Shape2D, context: String):
	if shape is CapsuleShape2D:
		check(shape.radius > 0 and shape.height >= 2 * shape.radius, "%s: invalid capsule geometry" % context)
	elif shape is RectangleShape2D:
		check(shape.size.x > 0 and shape.size.y > 0, "%s: invalid rectangle geometry" % context)
	elif shape is CircleShape2D:
		check(shape.radius > 0, "%s: invalid circle geometry" % context)

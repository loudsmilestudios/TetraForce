extends Node

var failures := 0
var checks := 0

func _ready():
	test_save_counts()
	await test_native_terrain()
	await test_decorations()
	test_texture_timing()
	test_rendering()
	test_keyboard_events()
	await test_push_lock()
	await test_key_chests()
	sfx.stop_all()
	# Let the audio server release queued playbacks before engine shutdown.
	await get_tree().create_timer(0.1).timeout
	print("Migration regression: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func test_save_counts():
	var save_name := "regression_counts_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var map := Node2D.new()
	map.name = "SaveCountsMap"
	add_child(map)
	network.current_map = map
	var handler = load("res://engine/dungeon_handler.gd").new()
	handler.name = "dungeon_handler"
	map.add_child(handler)
	global.ammo = {"bomb": 17, "arrow": 9, "tetrans": 7}
	global.equips = {"B": "Bomb", "X": "Bow", "Y": "Sword"}
	global.weapons = ["Sword", "Bomb", "Bow"]
	global.spiritpearl = 3
	global.max_health = 5.5
	network.states[str(handler.get_path())] = {"keys": 3, "thorn_order": 2}
	check(global.save_game_data(save_name), "Count regression save must be written")
	global.clean_session_data()
	network.states = {}
	check(global.load_game_data(save_name), "Existing base64 JSON save format must load")
	for ammo_type in ["bomb", "arrow", "tetrans"]:
		check(typeof(global.ammo[ammo_type]) == TYPE_INT, "%s count must load as an integer" % ammo_type)
	check(global.ammo == {"bomb": 17, "arrow": 9, "tetrans": 7}, "Loading must preserve ammo and currency amounts")
	check(typeof(global.spiritpearl) == TYPE_INT and global.spiritpearl == 3, "Spirit pearl count must load as an integer")
	check(global.max_health == 5.5 and global.health == 5.5, "Loading must preserve fractional health")
	check(global.equips.B == "Bomb" and global.weapons.has("Bow"), "Loading must preserve equipped and owned weapons")
	network.request_persistent_state(handler)
	check(typeof(handler.keys) == TYPE_INT and handler.keys == 3, "Saved dungeon keys must restore as an integer")
	check(typeof(handler.thorn_order) == TYPE_INT and handler.thorn_order == 2, "Saved thorn order must restore as an integer")

	var hud = load("res://ui/hud/hud.tscn").instantiate()
	add_child(hud)
	hud.update_weapons()
	hud.update_tetrans()
	hud.update_keys()
	check(hud.get_node("hud2d/buttons/B/count").text == "17", "Loaded bomb HUD must show a whole-number count")
	check(hud.get_node("hud2d/buttons/X/count").text == "9", "Loaded arrow HUD must show a whole-number count")
	check(hud.get_node("tetrans/tetrans").text == "007", "Loaded currency HUD must retain zero padding without decimals")
	check(hud.get_node("keys/keys").text == "3", "Loaded key HUD must show a whole-number count")
	global.ammo.bomb -= 1
	global.ammo.tetrans = 0
	handler.set_keys(handler.keys + 1)
	hud.update_weapons()
	hud.update_tetrans()
	hud.update_keys()
	check(hud.get_node("hud2d/buttons/B/count").text == "16", "Spending loaded ammo must retain integer display")
	check(hud.get_node("tetrans/tetrans").text == "000", "Zero currency must retain integer display and padding")
	check(hud.get_node("keys/keys").text == "4", "Adding a loaded key must retain integer display")
	hud.free()
	global.delete_save_data(save_name)
	map.free()
	network.current_map = null
	network.clean_session_data()

func test_decorations():
	var waterfall = load("res://tiles/decor/waterfall.tscn").instantiate()
	add_child(waterfall)
	check(waterfall.sprite_frames.get_frame_count("waterfall") == 6, "Waterfall must retain its six frames")
	check(waterfall.is_playing(), "Waterfall must autoplay")
	var frames_seen := {}
	for index in 30:
		frames_seen[waterfall.frame] = true
		await get_tree().create_timer(0.02).timeout
	check(frames_seen.size() > 1, "Waterfall must advance frames at runtime")
	waterfall.free()
	var decorations := []
	var seen := {}
	for file in DirAccess.get_files_at("res://tiles/decor"):
		if file.get_extension() == "tscn":
			var sprite = load("res://tiles/decor/" + file).instantiate()
			add_child(sprite)
			decorations.append(sprite)
			seen[sprite] = {}
			check(sprite.is_playing(), "%s must autoplay" % file)
	for index in 30:
		for sprite in decorations:
			seen[sprite][sprite.frame] = true
		await get_tree().create_timer(0.04).timeout
	for sprite in decorations:
		check(seen[sprite].size() > 1, "%s must advance frames" % sprite.name)
		sprite.free()

func test_texture_timing():
	for name in ["beach", "water", "dungeon_water", "dungeon1_water", "shallow_deadgrass", "shallow_deep", "shallow_grass", "shallow_shore"]:
		var resource_name = "shallow_dead_grass" if name == "shallow_deadgrass" else name
		var tileset: TileSet = load("res://tiles/%s_tileset.tres" % resource_name)
		var source := tileset.get_source(0) as TileSetAtlasSource
		var original: AnimatedTexture = load("res://tiles/%s_anim.tres" % name)
		var expected := 4.0 / 3.0 if name == "water" else 1.0
		check(source.texture is CompressedTexture2D, "%s must use an imported native atlas" % name)
		check(source.get_tiles_count() == 47, "%s must retain all original terrain patterns" % name)
		for index in source.get_tiles_count():
			var coords := source.get_tile_id(index)
			check(source.get_tile_animation_frames_count(coords) == original.frames, "%s/%s must animate all frames" % [name, coords])
			for frame in original.frames:
				check(is_equal_approx(source.get_tile_animation_frame_duration(coords, frame) / source.get_tile_animation_speed(coords), expected), "%s/%s must retain its old frame duration" % [name, coords])
		# The native frames must contain the original pixels in their original
		# order, not simply have the right frame count and timing.
		var atlas_image := source.texture.get_image()
		for frame in original.frames:
			var old_image := original.get_frame_texture(frame).get_image()
			old_image.convert(Image.FORMAT_RGBA8)
			var new_image := atlas_image.get_region(Rect2i(Vector2i(old_image.get_width() * frame, 0), old_image.get_size()))
			new_image.convert(Image.FORMAT_RGBA8)
			check(new_image.get_data() == old_image.get_data(), "%s frame %d must retain its original artwork" % [name, frame])

func test_rendering():
	for entry in [["overworld", "z_index", 200], ["dungeon1", "door_z_index", 200], ["bow_cave", "door_z_index", 200]]:
		var path = "res://maps/%s.tmx" % entry[0]
		if entry[0] == "bow_cave":
			path = "res://maps/overworld_caves/bow_cave.tmx"
		var level = load(path).instantiate()
		check(level.get_node(entry[1]).z_index == entry[2], "%s must retain authored foreground Z %s" % [entry[0], entry[2]])
		check(level.y_sort_enabled, "%s must sort actors and standing objects by ground position" % entry[0])
		for body in level.get_children():
			if body is PhysicsBody2D and !body.has_meta("z_index"):
				check(body.z_index == RenderLayers.ACTORS, "%s must share the player's actor plane" % body.name)
		level.free()
	check(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep", "Viewport must retain the Godot 3 stretch aspect")

func test_keyboard_events():
	# Godot 4.7 gives keyboard events a dedicated device ID. Serialized
	# Godot 3 bindings must still match those native keyboard events.
	var event := InputEventKey.new()
	event.device = InputEvent.DEVICE_ID_KEYBOARD
	event.keycode = KEY_UP
	event.pressed = true
	check(InputMap.event_is_action(event, "UP"), "Native keyboard events must match the migrated movement bindings")

class TestMap extends Node2D:
	signal player_entered(id)
	func is_game():
		return true
	func spawn_collectable(_kind, _position, _chance):
		pass

class TestZone extends Area2D:
	var collision_shape: CollisionShape2D
	var shape: RectangleShape2D

func fill_terrain(layer: TileMapLayer, cells: Array):
	layer.clear()
	for cell in cells:
		layer.set_cell(cell, 0, Vector2i(3, 3))
	TerrainTiles.refresh(layer, cells)

func test_native_terrain():
	network.initialize()
	var map := TestMap.new()
	map.name = "NativeTerrainMap"
	add_child(map)
	network.current_map = map
	network.map_hosts[map.name] = network.pid
	var square := []
	for x in range(-1, 2):
		for y in range(-1, 2):
			square.append(Vector2i(x, y))
	for kind in ["beach", "dungeon1_water", "dungeon_water", "shallow_dead_grass", "shallow_deep", "shallow_grass", "shallow_shore", "tall_grass", "water", "wheat", "holes"]:
		var template = load("res://tiles/%s.tscn" % kind).instantiate()
		check(template is TileMapLayer and template.get_script() != null, "%s template must instantiate with its gameplay script" % kind)
		template.free()
	for kind in ["tall_grass", "wheat"]:
		var layer = load("res://tiles/%s.tscn" % kind).instantiate()
		fill_terrain(layer, square)
		map.add_child(layer)
		check(layer.get_cell_atlas_coords(Vector2i.ZERO) == Vector2i(1, 1), "%s interior must use the original full-neighborhood tile" % kind)
		layer.process_tile(Vector2i.LEFT)
		check(layer.get_used_cells().size() == 8, "Cutting %s must erase exactly one cell" % kind)
		check(layer.get_cell_atlas_coords(Vector2i.ZERO) == Vector2i(0, 1), "Cutting %s must expose its neighbor's west edge" % kind)
		fill_terrain(layer, square)
		layer.cut_cells = [Vector2i.LEFT]
		check(layer.get_cell_atlas_coords(Vector2i.ZERO) == Vector2i(0, 1), "Restored %s cuts must repaint edges for late joiners" % kind)
		fill_terrain(layer, [Vector2i.ZERO, Vector2i(1, 1)])
		check(layer.get_cell_atlas_coords(Vector2i.ZERO) == Vector2i(3, 3), "%s diagonal-only contact must remain isolated" % kind)
		fill_terrain(layer, [Vector2i.ZERO, Vector2i.UP, Vector2i.LEFT])
		check(layer.get_cell_atlas_coords(Vector2i.ZERO) == Vector2i(7, 3), "%s must retain an empty northwest corner" % kind)
		fill_terrain(layer, [Vector2i.ZERO, Vector2i.UP, Vector2i.LEFT, Vector2i(-1, -1)])
		check(layer.get_cell_atlas_coords(Vector2i.ZERO) == Vector2i(2, 2), "%s must connect its filled northwest corner" % kind)
		layer.free()

	var water = load("res://tiles/water.tscn").instantiate()
	fill_terrain(water, square)
	map.add_child(water)
	water.clear_water(water.to_global(water.map_to_local(Vector2i.LEFT)))
	check(water.get_used_cells().size() == 8 and water.get_cell_atlas_coords(Vector2i.ZERO) == Vector2i(0, 1), "Removing water must repaint its surviving shore")
	var zone := TestZone.new()
	zone.shape = RectangleShape2D.new()
	zone.shape.size = Vector2(128, 128)
	zone.collision_shape = CollisionShape2D.new()
	zone.collision_shape.shape = zone.shape
	zone.add_child(zone.collision_shape)
	map.add_child(zone)
	water.set_default_state(zone)
	check(water.get_used_cells().size() == 9 and water.get_cell_atlas_coords(Vector2i.ZERO) == Vector2i(1, 1), "Resetting water must restore occupancy and reconnect its shore")
	water.free()

	var player = load("res://entities/player/player.tscn").instantiate()
	map.add_child(player)
	player.set_process(false)
	player.set_physics_process(false)
	var hit_shape = player.hitbox.get_child(0).shape
	check(is_equal_approx(hit_shape.radius, 5.5) and is_equal_approx(hit_shape.height, 20.0), "Player combat hitbox must retain its Godot 3 geometry")
	var boss = load("res://entities/bosses/sample_boss.tscn").instantiate()
	boss.automatic_boss_bar = false
	map.add_child(boss)
	boss.set_physics_process(false)
	check(boss.managed_entities.size() == 3, "Sample boss must register all three managed entities")
	for entity in boss.managed_entities:
		check(entity.is_connected("damaged", Callable(boss, "_on_entity_damaged").bind(entity)), "Managed boss entities must report damage")
	var hud = load("res://ui/hud/hud.tscn").instantiate()
	player.add_child(hud)
	var overlay = hud.boss_overlay
	for animation_player in [overlay.animation_player, overlay.animation_player.get_node("AnimationPlayer")]:
		animation_player.play("show_bossbar")
		animation_player.advance(1.1)
		check(overlay.bossbar.visible, "Both boss-bar animation players must resolve the bar")
		animation_player.play("hide_bossbar")
		animation_player.advance(1.1)
		check(!overlay.bossbar.visible, "Both boss-bar animations must hide the bar")
	network.complete()
	await get_tree().process_frame

class PushPlayer extends Node2D:
	var last_movedir = Vector2.UP
	func get_push_direction():
		return last_movedir
	func anim_switch(_animation):
		pass

func test_push_lock():
	network.initialize()
	var map := TestMap.new()
	map.name = "PushLockMap"
	add_child(map)
	network.current_map = map
	network.map_hosts[map.name] = network.pid
	global.player = PushPlayer.new()
	map.add_child(global.player)
	global.player.position = Vector2(1000, 1000)
	global.player.set_physics_process(true)
	for kind in ["block", "statue", "floating_barrel", "gravestone"]:
		var body = load("res://tiles/%s.tscn" % kind).instantiate()
		body.position = Vector2(8, 8)
		map.add_child(body)
		await get_tree().physics_frame
		body.attempt_move(Vector2.UP)
		body.attempt_move(Vector2.RIGHT)
		check(body.ray.target_position == Vector2.UP * 16, "%s must reserve the initial ray direction" % kind)
		await get_tree().create_timer(0.12).timeout
		check(body.target_position == Vector2(8, -8), "%s must commit the initial upward destination" % kind)
		body.attempt_move(Vector2.RIGHT)
		check(body.target_position == Vector2(8, -8), "%s cannot be steered while moving" % kind)
		await body.tween.finished
		check(body.position.is_equal_approx(Vector2(8, -8)), "%s must finish on the committed axis" % kind)
		body.free()

		body = load("res://tiles/%s.tscn" % kind).instantiate()
		body.position = Vector2(8, 8)
		map.add_child(body)
		body.attempt_move(Vector2.UP)
		if kind == "gravestone":
			body.target_position = Vector2(8, 8)
		else:
			body.set_default_state()
		await get_tree().create_timer(0.15).timeout
		check(body.position.is_equal_approx(Vector2(8, 8)), "%s reset must invalidate a pending push" % kind)
		body.free()

		body = load("res://tiles/%s.tscn" % kind).instantiate()
		body.position = Vector2(8, 8)
		map.add_child(body)
		body.attempt_move(Vector2.UP)
		await get_tree().create_timer(0.12).timeout
		if kind == "gravestone":
			body.target_position = Vector2(8, 8)
		else:
			body.set_default_state()
		await get_tree().create_timer(0.15).timeout
		check(body.position.is_equal_approx(Vector2(8, 8)), "%s reset must cancel active inertia" % kind)
		check(global.player.is_physics_processing(), "%s cancellation must not leave the player frozen" % kind)
		body.free()
	network.complete()
	await get_tree().process_frame

class KeyHud extends Node:
	var updates := 0
	func update_keys():
		updates += 1

func test_key_chests():
	network.initialize()
	for path in ["res://maps/overworld_caves/bow_cave.tmx", "res://maps/dungeon1.tmx"]:
		var level = load(path).instantiate()
		var handler = level.get_node_or_null("dungeon_handler")
		check(is_instance_valid(handler), "%s must preserve the unnamed handler prefab's root name" % path)
		if !is_instance_valid(handler):
			level.free()
			continue
		var chest = null
		var lock = null
		for child in level.get_children():
			if child.get("def") == "dungeon" and chest == null:
				chest = child
			if child.get_script() == load("res://tiles/lockblock.gd") and lock == null:
				lock = child
		check(chest != null and lock != null, "%s must provide a real key chest and lock for the regression" % path)
		if chest == null or lock == null:
			level.free()
			continue

		var map := TestMap.new()
		map.name = level.name
		add_child(map)
		network.current_map = map
		network.map_hosts[map.name] = network.pid
		global.player = null
		# Restore keys before a player/HUD exists, just as the child
		# NetworkObject can do during a real map's initialization.
		network.states[str(map.get_path()) + "/dungeon_handler"] = {"keys": 3, "thorn_order": 2}
		for object in [handler, chest, lock]:
			clear_owners(object)
			object.reparent(map, false)
		level.free()
		check(handler.keys == 3 and handler.thorn_order == 2, "Dungeon state must restore before player initialization")

		var player = load("res://entities/player/player.tscn").instantiate()
		map.add_child(player)
		player.set_process(false)
		player.set_physics_process(false)
		player.hud = KeyHud.new()
		player.add_child(player.hud)
		global.player = player
		player.spritedir = "Up"
		chest.chest_spawn()
		chest.interact(player)
		chest.interact(player)
		check(handler.keys == 4, "Opening the key chest must award exactly one key")
		check(player.state == "acquire", "Key chest must enter its acquisition animation")
		check(player.hud.updates == 1, "The key award must refresh the HUD")
		await get_tree().create_timer(1.1).timeout
		check(player.state == "default", "Key acquisition must restore player control")
		check(!chest.get_node("Item").visible, "Key acquisition must hide the held key")
		check(chest.opened and !chest.acquiring, "Chest must finish its one-shot acquisition")
		lock.interact(player)
		check(handler.keys == 3 and !lock.locked, "The acquired key must work with the real map's lock")
		map.free()
		global.player = null
	network.complete()
	await get_tree().process_frame

func clear_owners(node: Node):
	node.owner = null
	for child in node.get_children():
		clear_owners(child)

func check(condition: bool, message: String):
	checks += 1
	if !condition:
		failures += 1
		push_error(message)

extends Node

class TestMap extends Node2D:
	signal player_entered(id)
	func is_game():
		return true

var checks := 0
var failures := 0
var pixel_checks := 0
var viewport: SubViewport
var map: TestMap
var player: Player
var rendered := DisplayServer.get_name() != "headless"

func _ready():
	network.initialize()
	viewport = SubViewport.new()
	viewport.size = Vector2i(64, 64)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	map = TestMap.new()
	map.name = "RenderingTestMap"
	map.y_sort_enabled = true
	network.current_map = map
	network.map_hosts[map.name] = network.pid
	viewport.add_child(map)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(network.pid)
	map.add_child(player)
	player.set_process(false)
	player.set_physics_process(false)
	player.anim.active = false
	global.player = player
	color_sprite(player.sprite, Color.GREEN)
	await test_ship_barrel()
	await test_ground_enemies()
	await test_ui_theme()
	if "--require-rendering" in OS.get_cmdline_user_args():
		check(pixel_checks > 0, "Rendered regression run must actually compare framebuffer pixels")
	network.complete()
	global.player = null
	sfx.stop_all()
	await get_tree().create_timer(0.1).timeout
	print("Rendering regression: %d checks (%d pixel checks), %d failures" % [checks, pixel_checks, failures])
	get_tree().quit(1 if failures else 0)

func check(condition: bool, message: String):
	checks += 1
	if !condition:
		failures += 1
		push_error(message)

func effective_z(item: CanvasItem) -> int:
	var result := 0
	var current: Node = item
	while current is CanvasItem:
		result += current.z_index
		if !current.z_as_relative:
			break
		current = current.get_parent()
	return result

func color_sprite(sprite: Sprite2D, color: Color):
	# Replace only artwork with solid masks. Actual scene hierarchy, Z flags,
	# sprite dimensions and animation tracks still decide the visible pixel.
	var frame_size := sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes)
	var image := Image.create(int(frame_size.x) * sprite.hframes, int(frame_size.y) * sprite.vframes, false, Image.FORMAT_RGBA8)
	image.fill(color)
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.material = null
	sprite.modulate = Color.WHITE

func check_overlap(expected: Color, message: String):
	if !rendered:
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	pixel_checks += 1
	check(image.get_pixel(32, 32).is_equal_approx(expected), message)

func test_ship_barrel():
	# Exercise a real imported ship barrel and its neighboring water instead
	# of substituting an empty map or calling the floating animation directly.
	var level = load("res://maps/dungeon1.tmx").instantiate()
	var water = level.get_node("water")
	var barrel = null
	var direction := Vector2.ZERO
	for child in level.get_children():
		if child.get_script() != load("res://tiles/floating_barrel.gd"):
			continue
		for candidate in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			var cell = water.local_to_map(water.to_local(child.position + candidate * 16))
			if water.get_cell_source_id(cell) != -1:
				barrel = child
				direction = candidate
				break
		if barrel:
			break
	check(barrel != null, "Ship dungeon must provide a barrel beside water")
	if !barrel:
		level.free()
		return
	water.owner = null
	water.reparent(map, false)
	barrel.owner = null
	barrel.reparent(map, false)
	level.free()
	var sprite = barrel.get_node("Sprite2D")
	var anim = barrel.get_node("AnimationPlayer")
	color_sprite(sprite, Color.RED)
	anim.advance(0.0)
	map.position = Vector2(32, 32) - barrel.position
	check(effective_z(sprite) == effective_z(player.sprite), "Standing barrel must share the actor plane for Y-sorting")
	player.position = barrel.position + Vector2(0, -4)
	await check_overlap(Color.RED, "Standing barrel must cover a player behind it")
	player.position = barrel.position + Vector2(0, 4)
	await check_overlap(Color.GREEN, "Standing barrel must not cover a player in front of it")
	player.position = Vector2(-1000, -1000)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var destination = barrel.position + direction * 16
	var cell = water.local_to_map(water.to_local(destination))
	barrel.attempt_move(direction)
	await get_tree().create_timer(1.8).timeout
	check(barrel.pushed and anim.current_animation == "floating", "Water push must complete the real sink-to-floating transition")
	check(water.get_cell_source_id(cell) == -1 and barrel.get_node("CollisionShape2D").disabled, "Settled barrel must provide a passable crossing")
	check(effective_z(sprite) < effective_z(player.sprite), "Settled barrel must render below the player, independently of Y-sort")
	map.position = Vector2(32, 32) - barrel.position
	for offset in [-4, 0, 4]:
		player.position = barrel.position + Vector2(0, offset)
		await check_overlap(Color.GREEN, "Player must render above the platform across its entire crossing (Y offset %d)" % offset)
	barrel.set_default_state()
	anim.advance(0.0)
	check(barrel.target_position == barrel.home_position, "Reset must restore the destination sent to joining peers")
	var peer_barrel = load("res://tiles/floating_barrel.tscn").instantiate()
	peer_barrel.position = barrel.home_position
	peer_barrel.hide()
	map.add_child(peer_barrel)
	peer_barrel.get_node("NetworkObject").receive_update({"target_position": barrel.target_position, "pushed": barrel.pushed})
	await get_tree().create_timer(0.15).timeout
	check(peer_barrel.position.is_equal_approx(barrel.position), "Restoring reset barrel state must not move a peer back into the water")
	peer_barrel.free()
	anim.play("floating")
	anim.advance(0.0)
	check(effective_z(sprite) < effective_z(player.sprite), "Floating animation must establish its own draw plane when entered directly")
	barrel.set_default_state()
	barrel.set_pushed(true)
	await get_tree().create_timer(0.1).timeout
	barrel.set_default_state()
	await get_tree().create_timer(1.6).timeout
	check(!barrel.pushed and anim.assigned_animation == "default", "Reset must invalidate a pending sinking animation")
	check(!barrel.get_node("CollisionShape2D").disabled, "Canceled sinking must not turn a reset barrel into a ghost platform")
	anim.play("sink")
	anim.advance(0.65)
	check(barrel.get_node("splash").visible, "Reset regression must interrupt a visible splash")
	barrel.set_default_state()
	anim.advance(0.0)
	check(!barrel.get_node("splash").visible, "Reset must clear the interrupted splash")
	check(effective_z(sprite) == effective_z(player.sprite), "Reset must restore standing barrel Y-sorting")
	barrel.free()
	water.free()

func test_ground_enemies():
	map.position = Vector2.ZERO
	for kind in ["slime", "knawblin", "smashroom", "sneaky_bush", "thief_cat", "turtle", "stalfos", "pirafaux"]:
		var enemy = load("res://entities/enemies/%s/%s.tscn" % [kind, kind]).instantiate()
		enemy.position = Vector2(32, 32)
		map.add_child(enemy)
		enemy.set_process(false)
		enemy.set_physics_process(false)
		enemy.anim.active = false
		color_sprite(enemy.sprite, Color.RED)
		check(effective_z(enemy.sprite) == effective_z(player.sprite), "%s sprite must participate in actor Y-sorting" % kind)
		player.position = enemy.position + Vector2(0, -4)
		await check_overlap(Color.RED, "%s must cover a player standing behind it" % kind)
		player.position = enemy.position + Vector2(0, 4)
		await check_overlap(Color.GREEN, "%s must not cover a player standing in front of it" % kind)
		enemy.free()

func ui_frame(ui_viewport: SubViewport, screenshot_name: String = "") -> Image:
	if !rendered:
		return null
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := ui_viewport.get_texture().get_image()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--screenshots=") and !screenshot_name.is_empty():
			var path := argument.trim_prefix("--screenshots=").path_join(screenshot_name + ".png")
			check(image.save_png(path) == OK, "UI screenshot must be saved: %s" % path)
	return image

func test_ui_theme():
	var ui_viewport := SubViewport.new()
	ui_viewport.size = Vector2i(256, 144)
	ui_viewport.disable_3d = true
	ui_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(ui_viewport)
	# Both entry points use the original half-scale layout. Resolve styles
	# through the actual scenes, including the in-game panel's partial theme.
	for scene in ["main", "options_panel"]:
		var host := Control.new()
		host.size = Vector2(256, 144)
		ui_viewport.add_child(host)
		var path := "res://engine/main.tscn" if scene == "main" else "res://ui/options/options_panel.tscn"
		var settings = load(path).instantiate()
		host.add_child(settings)
		if scene == "main":
			# Let the main menu finish its delayed initial focus assignment.
			await get_tree().create_timer(0.6).timeout
			settings.hide_menus()
			settings.get_node("options").show()
		await get_tree().process_frame
		await get_tree().process_frame
		var options: TabContainer = settings.get_node("options" if scene == "main" else "Options")
		var tabs := options.get_tab_bar()
		for entry in [["tab_selected", "button.png"], ["tab_unselected", "button_push.png"], ["tab_hovered", "button_push.png"]]:
			var style := tabs.get_theme_stylebox(entry[0]) as StyleBoxTexture
			check(style != null, "%s %s must resolve the custom texture instead of the engine's default tab style" % [scene, entry[0]])
			if style:
				check(style.texture.resource_path.ends_with(entry[1]), "%s %s must retain the original tab artwork" % [scene, entry[0]])
		check(tabs.get_theme_font("font").get_font_name() == "monogram", "%s tab labels must use the original font" % scene)
		check(tabs.get_theme_font_size("font_size") == 16, "%s tab labels must retain the original font size" % scene)
		for index in options.get_tab_count():
			var rect := tabs.get_tab_rect(index)
			var text_size := tabs.get_theme_font("font").get_string_size(options.get_tab_title(index), HORIZONTAL_ALIGNMENT_LEFT, -1, tabs.get_theme_font_size("font_size"))
			check(rect.size.x - text_size.x >= 16 and rect.size.y - text_size.y >= 12, "%s tab %d must have room around its text" % [scene, index])
			check(rect.has_area() and rect.end.x <= tabs.size.x, "%s tab %d must remain fully visible with padding" % [scene, index])
		var input: LineEdit = options.get_node("Character/characterselect/name")
		check(input.alignment == HORIZONTAL_ALIGNMENT_CENTER, "%s player-name input must be centered" % scene)
		check(input.get_theme_font_size("font_size") == 16, "%s player-name input must retain the original font size" % scene)
		check(input.get_minimum_size().y <= input.size.y, "%s player-name input must fit its authored height" % scene)
		var label: Label = options.get_node("Character/characterselect/Label")
		check(label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "%s character description must retain alignment and wrapping" % scene)
		for index in options.get_tab_count():
			options.current_tab = index
			await get_tree().process_frame
			check(options.get_current_tab_control().visible, "%s tab %d must be selectable" % [scene, index])
			await ui_frame(ui_viewport, "tetra_%s_%s" % [scene, options.get_tab_title(index).to_lower()])
		host.free()

	# Compare the rendered corner artwork at two input widths. A lost texture
	# margin stretches these pixels along with the entire background image.
	ui_viewport.size = Vector2i(512, 288)
	await test_button_padding(ui_viewport)
	var input := LineEdit.new()
	input.position = Vector2(8, 8)
	ui_viewport.add_child(input)
	var style := input.get_theme_stylebox("normal") as StyleBoxTexture
	check(style != null, "Text inputs must use the original textured panel")
	if style:
		var source := style.texture.get_image()
		for width in [128, 240]:
			input.size = Vector2(width, 40)
			var image: Image = await ui_frame(ui_viewport)
			if image:
				var matches := true
				var compared := 0
				for y in range(1, 8):
					for x in range(1, 8):
						var expected := source.get_pixel(x, y)
						# Transparent texels reveal the viewport background.
						if is_equal_approx(expected.a, 1.0):
							compared += 1
							matches = matches and image.get_pixel(8 + x, 8 + y).is_equal_approx(expected)
				pixel_checks += 1
				check(matches and compared > 0, "Input border must retain its original corner pixels at width %d" % width)
	input.free()

	# Rasterize a real pixel font and check its glyph atlas, so auto hinting,
	# subpixel positioning, or oversampling cannot silently blur the lettering.
	for path in ["font", "dogicapixel", "dogicapixelbold"]:
		var font: FontFile = load("res://ui/theme/%s.ttf" % path)
		check(font.subpixel_positioning == TextServer.SUBPIXEL_POSITIONING_DISABLED, "%s must place pixel glyphs on whole pixels" % path)
		check(font.hinting == TextServer.HINTING_NORMAL, "%s must retain Godot 3's full hinting" % path)
		var size := 16 if path == "font" else 8
		font.render_range(0, Vector2i(size, 0), 32, 126)
		var sharp := font.get_texture_count(0, Vector2i(size, 0)) > 0
		for index in font.get_texture_count(0, Vector2i(size, 0)):
			var atlas := font.get_texture_image(0, Vector2i(size, 0), index)
			for y in atlas.get_height():
				for x in atlas.get_width():
					var alpha := atlas.get_pixel(x, y).a
					sharp = sharp and (is_zero_approx(alpha) or is_equal_approx(alpha, 1.0))
		check(sharp, "%s glyph atlas must retain crisp pixel edges" % path)

	var toggle := CheckButton.new()
	ui_viewport.add_child(toggle)
	check(toggle.get_theme_icon("checked").resource_path.ends_with("check_button_on.png"), "Enabled checkbox must use the original icon")
	check(toggle.get_theme_icon("unchecked").resource_path.ends_with("check_button_off.png"), "Disabled checkbox must use the original icon")
	toggle.free()
	var bar := ProgressBar.new()
	bar.theme = load("res://ui/theme/boss_overlay.tres")
	ui_viewport.add_child(bar)
	check(bar.get_theme_stylebox("fill") is StyleBoxTexture, "Boss health bar must use its original textured fill")
	check(bar.get_theme_stylebox("background") is StyleBoxTexture, "Boss health bar must use its original textured background")
	bar.free()
	ui_viewport.free()

func test_button_padding(ui_viewport: SubViewport):
	for theme_name in ["theme", "character_select"]:
		var button := Button.new()
		button.theme = load("res://ui/theme/%s.tres" % theme_name)
		button.text = "Save"
		button.position = Vector2(8, 8)
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
			button.add_theme_color_override(color_name, Color.WHITE)
		ui_viewport.add_child(button)
		var minimum := button.get_minimum_size()
		button.size = minimum.ceil()
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			button.disabled = state == "disabled"
			button.button_pressed = state in ["pressed", "hover_pressed"]
			var motion := InputEventMouseMotion.new()
			motion.position = button.position + button.size / 2.0 if state in ["hover", "hover_pressed"] else Vector2(400, 200)
			ui_viewport.push_input(motion)
			check(button.get_minimum_size().is_equal_approx(minimum), "%s button must retain its padded size in the %s state" % [theme_name, state])
			var image: Image = await ui_frame(ui_viewport)
			if image:
				var first_pixel := int(button.size.x)
				var last_pixel := -1
				for y in int(button.size.y):
					for x in int(button.size.x):
						if image.get_pixel(8 + x, 8 + y).is_equal_approx(Color.WHITE):
							first_pixel = mini(first_pixel, x)
							last_pixel = maxi(last_pixel, x)
				pixel_checks += 1
				check(last_pixel >= first_pixel and first_pixel >= 8 and button.size.x - last_pixel - 1 >= 8, "%s %s button text must have visible padding on both sides" % [theme_name, state])
		button.free()

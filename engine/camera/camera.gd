extends Camera2D

const SCREEN_SIZE = Vector2(256, 144)
const SCROLL_SPEED = 0.5

var target
var target_grid_pos = Vector2(0,0)
var last_target_grid_pos = Vector2(0,0)
var camera_rect = Rect2()
var player_cam

signal screen_change_started
signal screen_change_completed

func _ready():
	set_process(false)

func initialize(node):
	target = node
	position = get_grid_pos(target.position) * SCREEN_SIZE
	$Tween.connect("tween_started", self, "screen_change_started")
	$Tween.connect("tween_completed", self, "screen_change_completed")
	current = true

	set_process(true)

func _process(delta):
	if target == null:
		return
	if player_cam:
		return # Player cam is taking care of it
	
	target_grid_pos = get_grid_pos(target.position)
	
	camera_rect = Rect2(position, SCREEN_SIZE)
	
	if !$Tween.is_active() && !camera_rect.has_point(target.position):
		scroll_camera()
	
	last_target_grid_pos = target_grid_pos

func scroll_camera():
	$Tween.interpolate_property(self, "position", last_target_grid_pos * SCREEN_SIZE, target_grid_pos * SCREEN_SIZE, SCROLL_SPEED, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()

func get_grid_pos(pos):
	var x = floor(pos.x / SCREEN_SIZE.x)
	var y = floor(pos.y / SCREEN_SIZE.y)
	return Vector2(x,y)

# Attach a predefined personal camera to the target (being the current player, or so it should be)
func unlock_camera(limits):
	if !limits:
		return # Just in case
	if $Tween.is_active():
		# Wait for current tween to complete before unlocking camera to avoid (almost all) spazzing
		yield($Tween, "tween_completed")
		
	# Create and configure new camera to attach to the player
	player_cam = Camera2D.new()
	player_cam.current = true # Make camera active
	# Make it snappy, the camera that is
	player_cam.drag_margin_h_enabled = false 
	player_cam.drag_margin_v_enabled = false
	player_cam.limit_left = limits.left
	player_cam.limit_top = limits.top
	player_cam.limit_right = limits.right
	player_cam.limit_bottom = limits.bottom
		
	target.add_child(player_cam)

# Put camera back in default position, locked to a screen
func lock_camera():
	make_current()
	target.remove_child(player_cam)
	player_cam = null

func screen_change_started(object, nodepath):
	emit_signal("screen_change_started")

func screen_change_completed(object, nodepath):
	emit_signal("screen_change_completed")

extends CanvasLayer

signal scroll_complete()

export(String) var MUSIC = "town"
export(float) var SCROLL_SPEED = 18
export(float) var SCROLL_SPEED_UP_MULTIPLIER = 10
export(float) var SCROLL_TIP_DELAY = 5
export(float) var SCROLL_FADE_RATE = 0.05
export(float) var SCROLL_SHOW_RATE = 5
export(float) var SCROLL_COMPLETE_OFFSET = 100

var scroll_timer : Timer

onready var scrolling = $Credits
onready var tip = $Label

func _ready():
	
	if not scroll_timer:
		scroll_timer = Timer.new()
		add_child(scroll_timer)
	tip.modulate.a = 0
	scroll_timer.connect("timeout", self, "display_tip")
	scroll_timer.start(SCROLL_TIP_DELAY)
	
	yield(get_tree().create_timer(0.1), "timeout")
	sfx.set_music(MUSIC)

func _process(delta):
	
	if Input.is_action_pressed("START"):
		scrolling.rect_position.y = scrolling.rect_position.y - delta * SCROLL_SPEED * SCROLL_SPEED_UP_MULTIPLIER
	else:
		scrolling.rect_position.y = scrolling.rect_position.y - delta * SCROLL_SPEED
	if abs(scrolling.rect_position.y) > scrolling.rect_size.y * scrolling.rect_scale.y + SCROLL_COMPLETE_OFFSET:
		set_completed()

func display_tip():
	tip.modulate.a = 0
	tip.show()
	scroll_timer.disconnect("timeout", self, "display_tip")
	scroll_timer.disconnect("timeout", self, "fade_tip_out")
	scroll_timer.disconnect("timeout", self, "start_fade_tip_out")
	scroll_timer.connect("timeout", self, "fade_tip_in")
	scroll_timer.start(SCROLL_FADE_RATE)
		
func start_fade_tip_out():
	scroll_timer.disconnect("timeout", self, "display_tip")
	scroll_timer.disconnect("timeout", self, "fade_tip_in")
	scroll_timer.disconnect("timeout", self, "start_fade_tip_out")
	scroll_timer.connect("timeout", self, "fade_tip_out")
	scroll_timer.start(SCROLL_FADE_RATE)
	
func fade_tip_in():
	tip.modulate.a = clamp(tip.modulate.a + 0.1, 0, 1)
	if tip.modulate.a == 1:
		scroll_timer.disconnect("timeout", self, "display_tip")
		scroll_timer.disconnect("timeout", self, "fade_tip_out")
		scroll_timer.disconnect("timeout", self, "fade_tip_in")
		scroll_timer.connect("timeout", self, "start_fade_tip_out")
		scroll_timer.start(SCROLL_SHOW_RATE)
		
func fade_tip_out():
	tip.modulate.a = clamp(tip.modulate.a - 0.1, 0, 1)
	if tip.modulate.a == 0:
		scroll_timer.stop()

func set_completed():
	emit_signal("scroll_complete")
	self.set_process(false)
	return

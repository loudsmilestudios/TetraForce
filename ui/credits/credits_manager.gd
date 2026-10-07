extends CanvasLayer

signal scroll_complete()

@export var MUSIC: String = "town"
@export var SCROLL_SPEED: float = 18
@export var SCROLL_SPEED_UP_MULTIPLIER: float = 10
@export var SCROLL_TIP_DELAY: float = 5
@export var SCROLL_FADE_RATE: float = 0.05
@export var SCROLL_SHOW_RATE: float = 5
@export var SCROLL_COMPLETE_OFFSET: float = 100

var scroll_timer : Timer

@onready var scrolling = $Credits
@onready var tip = $Label

func _ready():
	
	if not scroll_timer:
		scroll_timer = Timer.new()
		add_child(scroll_timer)
	tip.modulate.a = 0
	scroll_timer.connect("timeout", Callable(self, "display_tip"))
	scroll_timer.start(SCROLL_TIP_DELAY)
	
	await get_tree().create_timer(0.1).timeout
	sfx.set_music(MUSIC)

func _process(delta):
	
	if Input.is_action_pressed("START"):
		scrolling.position.y = scrolling.position.y - delta * SCROLL_SPEED * SCROLL_SPEED_UP_MULTIPLIER
	else:
		scrolling.position.y = scrolling.position.y - delta * SCROLL_SPEED
	if abs(scrolling.position.y) > scrolling.size.y * scrolling.scale.y + SCROLL_COMPLETE_OFFSET:
		set_completed()

func display_tip():
	tip.modulate.a = 0
	tip.show()
	scroll_timer.disconnect("timeout", Callable(self, "display_tip"))
	scroll_timer.disconnect("timeout", Callable(self, "fade_tip_out"))
	scroll_timer.disconnect("timeout", Callable(self, "start_fade_tip_out"))
	scroll_timer.connect("timeout", Callable(self, "fade_tip_in"))
	scroll_timer.start(SCROLL_FADE_RATE)
		
func start_fade_tip_out():
	scroll_timer.disconnect("timeout", Callable(self, "display_tip"))
	scroll_timer.disconnect("timeout", Callable(self, "fade_tip_in"))
	scroll_timer.disconnect("timeout", Callable(self, "start_fade_tip_out"))
	scroll_timer.connect("timeout", Callable(self, "fade_tip_out"))
	scroll_timer.start(SCROLL_FADE_RATE)
	
func fade_tip_in():
	tip.modulate.a = clamp(tip.modulate.a + 0.1, 0, 1)
	if tip.modulate.a == 1:
		scroll_timer.disconnect("timeout", Callable(self, "display_tip"))
		scroll_timer.disconnect("timeout", Callable(self, "fade_tip_out"))
		scroll_timer.disconnect("timeout", Callable(self, "fade_tip_in"))
		scroll_timer.connect("timeout", Callable(self, "start_fade_tip_out"))
		scroll_timer.start(SCROLL_SHOW_RATE)
		
func fade_tip_out():
	tip.modulate.a = clamp(tip.modulate.a - 0.1, 0, 1)
	if tip.modulate.a == 0:
		scroll_timer.stop()

func set_completed():
	emit_signal("scroll_complete")
	self.set_process(false)
	return

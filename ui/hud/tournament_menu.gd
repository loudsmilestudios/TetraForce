extends Panel


var current_arena : String = ""

onready var hud = get_parent()
onready var arena_label = $ArenaTitle
onready var close_button = $CloseButton
onready var tournament_master : TournamentMaster = network.tournament_master

func _input(event):
	if Input.is_action_just_pressed("ESC"):
		yield(get_tree(), "idle_frame")
		hud.close_menus()

func _ready():
	hide()

func open_for_arena(arena) -> bool:
	if arena in tournament_master.ARENA_DATA:
		current_arena = arena
		arena_label.text = tournament_master.ARENA_DATA[arena].name
		
		close_button.grab_focus()
		show()
		return true
	return false

func _on_closed_pressed():
	hud.close_menus()

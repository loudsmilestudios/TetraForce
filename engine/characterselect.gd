extends Panel

var selected = 0
var player_name: String = ""

var options = {
	"Chain": "res://player/player.png",
	"Knot": "res://player/player2.png",
}

func _ready():
	$back.connect("pressed", self, "back_pressed")
	$forward.connect("pressed", self, "forward_pressed")
	update_skin()

func update_skin():
	$preview.texture = load(options.values()[selected])
	network.my_player_data.skin = options.values()[selected]
	$name.text = options.keys()[selected]

func back_pressed():
	selected = wrapi(selected - 1, 0, options.size())
	update_skin()

func forward_pressed():
	selected = wrapi(selected + 1, 0, options.size())
	update_skin()

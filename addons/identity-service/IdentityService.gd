extends HTTPRequest

signal identity_loaded(identity)

var my_identity : Identity

func _ready():
	if OS.has_environment("ITCHIO_API_KEY"):
		var id = ItchIdentity.new({"ITCHIO_API_KEY": OS.get_environment("ITCHIO_API_KEY")})
		if yield(id.load_identity(self),"completed"):
			my_identity = id
			
	# Intialize guest user
	if not my_identity:
		my_identity = Identity.new()
		yield(global, "options_loaded")
		my_identity.username = global.options.player_data.name
		my_identity.display_name = global.options.player_data.name
	
	emit_signal("identity_loaded", my_identity)

func load_token(token : String) -> Identity:
	var data = Identity.decode_token(token)
	if "ITCHIO_API_KEY" in data:
		return ItchIdentity.new(data)
	return Identity.new()

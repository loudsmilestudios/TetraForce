class_name ItchIdentity
extends Identity

var data
var validated = false

func _init(raw_token : Dictionary = {}):
	super(raw_token)
	platform = "itch"

func load_identity(http_client : HTTPRequest) -> bool:
	var decoded_token = self.decode_token(self.token)
	
	if not "ITCHIO_API_KEY" in decoded_token:
		handle_error("Missing JWT token!")
		return false
	
	http_client.request("https://itch.io/api/1/jwt/me", ["Authorization: %s" % decoded_token["ITCHIO_API_KEY"]], HTTPClient.METHOD_GET)
	var result = await http_client.request_completed
	if len(result) <= 3 || result[1] != 200:
		handle_error("Did not return 200!")
		return false
	var json = JSON.parse_string(result[3].get_string_from_utf8())
	if not json is Dictionary:
		handle_error("Failed to parse JSON!")
		return false
	
	if "errors" in json:
		for error in json["errors"]:
			handle_error(error)
			return false

	data = json
	username = data["user"]["username"]
	
	if "display_name" in data["user"]:
		display_name = data["user"]["display_name"]
	else:
		display_name = username
	
	if "cover_url" in data["user"]:
		profile_picture_url = data["user"]["cover_url"]
	if "url" in data["user"]:
		profile_url = data["user"]["url"]
	loaded = true
	emit_signal("loading_complete")
	return true

func _is_valid() -> bool:
	if not validated:
		var load_result = await self.load_identity(IdentityService)
		validated = load_result
	return validated

func handle_error(err):
	data = err
	emit_signal("loading_complete")
	printerr("ItchIdentity: %s" % err)
	loaded = true
	self.validated = false

class_name Identity

signal loading_complete

var display_name : String = ""
var username : String = ""
var profile_picture_url : String = ""
var profile_url : String = ""
var platform : String = "guest"
var token : String = ""
var loaded : bool = false

func _init(raw_token : Dictionary = {}):
	encode_token(raw_token)

func get_dict() -> Dictionary:
	return {
		"display_name" : display_name,
		"username" : username,
		"profile_picture_url" : profile_picture_url,
		"profile_url" : profile_url,
		"token" : token
	}

func from_dict(data : Dictionary) -> void:
	if "display_name" in data:
		display_name = data["display_name"]
	if "username" in data:
		username = data["username"]
	if "profile_picture_url" in data:
		profile_picture_url = data["profile_picture_url"]
	if "profile_url" in data:
		profile_url = data["profile_url"]
	if "token" in data:
		token = data["token"]

static func decode_token(token : String) -> Dictionary:
	var json : JSONParseResult = JSON.parse(Marshalls.base64_to_utf8(token))
	if json.error == OK:
		return json.result
	return {}

func encode_token(token_dict : Dictionary):
	token = Marshalls.utf8_to_base64(to_json(token_dict))

func is_valid() -> bool:
	if platform == "guest":
		loaded = true
	if self.has_method("_is_valid"):
		return self.call("_is_valid")
	yield(IdentityService.get_tree(), "idle_frame")
	return true

func _to_string() -> String:
	return "%s:%s" % [platform, username]


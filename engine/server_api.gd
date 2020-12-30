# For more information on API responses, please checkout the
# API Usage page on the infrastructure wiki
# https://github.com/josephbmanley/tetraforce-infrastructure/wiki/API-Usage

extends Node

export(String) var api_endpoint = "api.online.tetraforce.io"

var _http_client : HTTPRequest
var auth_token : String

func _ready():
	_http_client = HTTPRequest.new()
	add_child(_http_client)

##################
### Server API ###
##################

# Asynchronous coroutine.
# Requests API for data from a specific server
# Returns: {"message": [MESSAGE], "data" : [DATA] }
func get_server(lobby : String) -> Dictionary:
	return _api_request("get_servers", {"server" : lobby}, HTTPClient.METHOD_GET, false)

# Asynchronous coroutine.
# Requests API for a list of servers
# Returns: {"message": [MESSAGE], "data" : [DATA] }
func get_servers(page : int = 0) -> Dictionary:
	return _api_request("get_servers", {"page" : str(page)}, HTTPClient.METHOD_GET, false)

# Asynchronous coroutine.
# Requests API for creating a server
# Returns: {"message": [MESSAGE], "success" : [SUCCESS] }
func create_server(lobby : String = "") -> Dictionary:
	return _api_request("create_server", {"server" : lobby}, HTTPClient.METHOD_POST, false)

# Asynchronous coroutine.
# Requests API for stopping a server
# Returns: {"message": [MESSAGE], "success" : [SUCCESS] }
func stop_server(lobby : String = "") -> Dictionary:
	return _api_request("stop_server", {"server" : lobby}, HTTPClient.METHOD_POST, true)


################
### Auth API ###
################

# Asynchronous coroutine.
# Requests API for an auth token
# Returns: True if auth token was found and set
func login(username : String, password : String) -> bool:
	var result = yield(_api_request("auth/login", {"username" : username, "password" : password}, HTTPClient.METHOD_POST, false), "completed")
	if "success" in result and result["success"] and "AuthenticationResult" in result["message"]:
		if "AccessToken" in result["message"]["AuthenticationResult"]:
			auth_token = result["message"]["AuthenticationResult"]["AccessToken"]
			return bool(result["success"])

	return false

# Asynchronous coroutine.
# Requests API to create a new user
# Returns: {"message": [MESSAGE], "success" : [SUCCESS] }
func register(username : String, password : String, email : String) -> Dictionary:
	return _api_request("auth/register", {"username" : username, "password" : password, "email" : email}, HTTPClient.METHOD_POST, false)

# Asynchronous coroutine.
# Requests API for a user's profile data
# Returns: {"message": [MESSAGE], "success" : [SUCCESS] }
func get_profile() -> Dictionary:
	return _api_request("auth/profile", {}, HTTPClient.METHOD_GET, true)

# Asynchronous coroutine.
# Requests API to reset a user's password
# Returns: {"message": [MESSAGE], "success" : [SUCCESS] }
func reset_password(username : String) -> Dictionary:
	return _api_request("auth/reset", {"username" : username}, HTTPClient.METHOD_POST, false)

########################
### Helper Functions ###
########################

# Helper function to manage ALL API requests
func _api_request(path : String, params : Dictionary, method = HTTPClient.METHOD_GET, auth_required = false) -> Dictionary:
	
	# Build required request objects
	var request_string = "https://%s/%s%s" % [api_endpoint, path, _params_to_string(params)]	
	var headers : PoolStringArray = []

	# Update request with token if needed
	if auth_required:
		if auth_token:
			headers.append("Authorization: %s" % auth_token)
	
	# Make HTTP Requesst
	_http_client.request(request_string, headers, true, method)

	# Get and parse result
	var result = yield(_http_client, "request_completed")
	if len(result) > 3:
		if result[1] == 200:
			var json : JSONParseResult = JSON.parse(result[3].get_string_from_utf8())
			if json.error:
				return _build_error_message("Failed to parse response: %s" % json.error_string)
			return json.result
		elif result[1] == 503: # Check for permission denied errors
			_build_error_message("Unauthorized request!")
		else: # Return response code in error message if possible
			_build_error_message("Request failed! Response code: %s" % str(result[1]))
		
	return _build_error_message("Request failed!")

# Helper function for converting a dictionary into HTTP parameters
func _params_to_string(params : Dictionary) -> String:
	
	var param_strings = []
	for param in params:
		param_strings.append("%s=%s" % [param, str(params[param])])
	
	var params_string = ""
	for i in range(param_strings.size()):
		if i == 0:
			params_string += "?"

		params_string += param_strings[i]
		
		if i != params.size():
			params_string += "&"
	return params_string

# Helper function for generating client errors
func _build_error_message(message):
	return {"message":message, "success" : false}

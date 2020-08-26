extends Node

export(String) var api_endpoint = "stage.api.tetraforce.io"

var _http_client : HTTPRequest

func _ready():
	_http_client = HTTPRequest.new()
	add_child(_http_client)

# Asynchronous coroutine.
# Requests API for data from a specific server
# Returns: {"message": [MESSAGE], "data" : [DATA] }
func get_server(lobby : String) -> Dictionary:
	_http_client.request("https://" + api_endpoint + "/get_servers?server=" + str(lobby), [], true, HTTPClient.METHOD_GET)
	var result = yield(_http_client, "request_completed")
	if len(result) > 3 and result[1] == 200:
		var json : JSONParseResult = JSON.parse(result[3].get_string_from_utf8())
		if json.error:
			return _build_error_message(json.error_string)
		return json.result
		
	return _build_error_message("Request failed!")

# Asynchronous coroutine.
# Requests API for a list of servers
# Returns: {"message": [MESSAGE], "data" : [DATA] }
func get_servers(page : int = 0) -> Dictionary:
	_http_client.request("https://" + api_endpoint + "/get_servers?page=" + str(page), [], true, HTTPClient.METHOD_GET)
	var result = yield(_http_client, "request_completed")
	if len(result) > 3 and result[1] == 200:
		var json : JSONParseResult = JSON.parse(result[3].get_string_from_utf8())
		if json.error:
			return _build_error_message(json.error_string)
		return json.result
		
	return _build_error_message("Request failed!")

# Asynchronous coroutine.
# Requests API for creating a server
# Returns: {"message": [MESSAGE], "success" : [SUCCESS] }
func create_server(lobby : String = "") -> Dictionary:
	_http_client.request("https://" + api_endpoint + "/create_server?server=" + str(lobby), [], true, HTTPClient.METHOD_POST)
	var result = yield(_http_client, "request_completed")
	if len(result) > 3 and result[1] == 200:
		var json : JSONParseResult = JSON.parse(result[3].get_string_from_utf8())
		if json.error:
			return _build_error_message(json.error_string)
		return json.result
		
	return _build_error_message("Request failed!")

# Asynchronous coroutine.
# Requests API for stopping a server
# Returns: {"message": [MESSAGE], "success" : [SUCCESS] }
func stop_server(lobby : String = "") -> Dictionary:
	_http_client.request("https://" + api_endpoint + "/stop_server?server=" + str(lobby), [], true, HTTPClient.METHOD_POST)
	var result = yield(_http_client, "request_completed")
	if len(result) > 3 and result[1] == 200:
		var json : JSONParseResult = JSON.parse(result[3].get_string_from_utf8())
		if json.error:
			return _build_error_message(json.error_string)
		return json.result
		
	return _build_error_message("Request failed!")

# Helper function for generating client errors
func _build_error_message(message):
	return {"message":message, "success" : false}

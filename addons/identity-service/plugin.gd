tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("IdentityService", "res://addons/identity-service/IdentityService.gd")


func _exit_tree():
	remove_autoload_singleton("IdentityService")

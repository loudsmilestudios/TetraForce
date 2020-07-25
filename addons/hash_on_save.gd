tool
extends EditorPlugin

var PATH: String = "res://version.dat"

func save_external_data() -> void:
	var file = File.new()
	file.open(PATH, File.WRITE)
	var time : int = JSON.print(OS.get_datetime()).hash()
	file.store_line(str(time))
#	print(time)
	file.close()

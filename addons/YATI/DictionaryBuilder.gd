# MIT License
#
# Copyright (c) 2023-2025 Roland Helmerichs
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends RefCounted

enum FileType {
	Xml,
	Json,
	Unknown
}

func get_dictionary(tiled_file_content: PackedByteArray, source_file: String):
	var type = FileType.Unknown
	var extension = source_file.get_file().get_extension().to_lower()
	if ["tmx", "tsx", "xml", "tx"].find(extension) >= 0:
		type = FileType.Xml
	elif ["tmj", "tsj", "json", "tj", "tiled-project"].find(extension) >= 0:
		type = FileType.Json
	else:
		var chunk = tiled_file_content.slice(0, 11).get_string_from_utf8()
		if chunk.starts_with("<?xml "):
			type = FileType.Xml
		elif chunk.starts_with("{ \""):
			type = FileType.Json

	match type:
		FileType.Xml:
			var dict_builder = preload("DictionaryFromXml.gd").new()
			return dict_builder.create(tiled_file_content, source_file)
		FileType.Json:
			var json = JSON.new()
			if json.parse(tiled_file_content.get_string_from_utf8()) == OK:
				return json.data
		FileType.Unknown:
			printerr("ERROR: File '" + source_file + "' has an unknown type. -> Continuing but result may be unusable")

	return null

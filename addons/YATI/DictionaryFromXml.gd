# MIT License
#
# Copyright (c) 2023-2026 Roland Helmerichs
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

var _xml = preload("XmlParserCtrl.gd").new()
var _current_element = ""
var _current_group_level: int = 0
var _current_properties_level: int = 0
var _result = {}
var _current_dictionary = _result
var _current_array = []
var _csv_encoded = true
var _is_map: bool
var _in_tileset: bool = false

func create(tiled_file_content: PackedByteArray, source_file_name: String):
	var err = _xml.open(tiled_file_content, source_file_name)
	if err != OK:
		return null

	_current_element = _xml.next_element()
	_current_dictionary = _result
	var base_attributes = _xml.get_attributes()

	_current_dictionary["type"] = _current_element
	insert_attributes(_current_dictionary, base_attributes)
	_is_map = _current_element == "map"

	var base_element = _current_element
	var base_group_level = _current_group_level
	while err == OK and (not _xml.is_end() or _current_element != base_element or
			(base_element == "group" and _current_element == "group" and _current_group_level == base_group_level)):
		_current_element = _xml.next_element()
		if _current_element == null:
			err = ERR_PARSE_ERROR
			break
		if _xml.is_end():
			if _current_element == "group":
				_current_group_level -= 1
			if _current_element == "properties":
				_current_properties_level += 1
			continue
		if _current_element == "group" and not _xml.is_empty():
			_current_group_level += 1
		if _current_element == "properties" and not _xml.is_empty():
			_current_properties_level += 1
		var c_attributes = _xml.get_attributes()
		var dictionary_bookmark = _current_dictionary
		if _xml.is_empty():
			err = simple_element(_current_element, c_attributes)
		else:
			err = nested_element(_current_element, c_attributes)
		_current_dictionary = dictionary_bookmark

	if err == OK:
		return _result
	else:
		print("Import aborted with ", err, " error.")
		return null

func simple_element(element_name: String, attribs: Dictionary):
	if element_name == "image":
		_current_dictionary["image"] = attribs["source"]
		if attribs.has("width"):
			_current_dictionary["imagewidth"] = int(attribs["width"])
		if attribs.has("height"):
				_current_dictionary["imageheight"] = int(attribs["height"])
		if attribs.has("trans"):
			_current_dictionary["transparentcolor"] = attribs["trans"]
		return OK
	if element_name == "wangcolor":
		element_name = "color"
	if element_name == "point":
		_current_dictionary["point"] = true
		return OK
	if element_name == "ellipse":
		_current_dictionary["ellipse"] = true
		return OK
	if element_name == "capsule":
		_current_dictionary["capsule"] = true
		return OK

	var dict_key = element_name
	if (element_name == "objectgroup" and (not _is_map or _in_tileset)) or (element_name == "text") or (element_name == "tileoffset") or (element_name == "grid"):
		# Create a single dictionary, not an array.
		_current_dictionary[dict_key] = {}
		_current_dictionary = _current_dictionary[dict_key]
		if attribs.size() > 0:
			insert_attributes(_current_dictionary, attribs)
	else:
		if dict_key == "polygon" or dict_key == "polyline":
			var arr = []
			for pt in attribs["points"].split(" "):
				var dict = {}
				var x = float(pt.split(",")[0])
				var y = float(pt.split(",")[1])
				dict["x"] = x
				dict["y"] = y
				arr.append(dict)
			_current_dictionary[dict_key] = arr
		elif dict_key == "frame" or dict_key == "property":
			# i.e. will be part of the superior array (animation or properties)
			var dict = {}
			if _current_properties_level > 1:
				_current_array = []
				_current_dictionary[attribs["name"]] = _current_array
				insert_attributes(dict, attribs, true)
			else:
				insert_attributes(dict, attribs)
			_current_array.append(dict)
			if dict.has("type"):
				if dict["type"] == "list":
					_current_dictionary = dict
					_current_array = []
					_current_dictionary["value"] = _current_array
				elif dict["type"] == "class":
					_current_dictionary = {}
					dict["value"] = _current_dictionary
		else:
			if dict_key == "objectgroup" or dict_key == "imagelayer":
				# to be later added to the layer attributes (by insert_attributes)
				attribs["type"] = dict_key
				dict_key = "layer"
			if dict_key == "group":
				# Add nested layers array
				attribs["type"] = "group"
				if _current_dictionary.has("layers"):
					_current_array = _current_dictionary["layers"]
				else:
					_current_array = []
					_current_dictionary["layers"] = _current_array
				dict_key = "layer"
			if dict_key != "animation" and dict_key != "properties":
				dict_key = dict_key + "s"
			if dict_key != "items":
				if dict_key == "properties" and _current_properties_level > 1:
					return OK
				if _current_dictionary.has(dict_key):
					_current_array = _current_dictionary[dict_key]
				else:
					_current_array = []
					_current_dictionary[dict_key] = _current_array
			if dict_key != "animation" and dict_key != "properties":
				_current_dictionary = {}
				_current_array.append(_current_dictionary)
			if dict_key == "wangtiles":
				_current_dictionary["tileid"] = int(attribs["tileid"])
				var arr = []
				for s in attribs["wangid"].split(","):
					arr.append(int(s))
				_current_dictionary["wangid"] = arr
			else:
				if attribs.size() > 0:
					insert_attributes(_current_dictionary, attribs)
			if dict_key == "items":
				if attribs.has("type") and attribs["type"] == "list":
					_current_array = []
					_current_dictionary["value"] = _current_array
	return OK        


func nested_element(element_name: String, attribs: Dictionary):
	var err = OK
	if element_name == "wangsets":
		return OK
	elif element_name == "data":
		_current_dictionary["type"] = "tilelayer"
		if attribs.has("encoding"):
			_current_dictionary["encoding"] = attribs["encoding"]
			_csv_encoded = attribs["encoding"] == "csv"
		if attribs.has("compression"):
			_current_dictionary["compression"] = attribs["compression"]
		return OK
	elif element_name == "tileset":
		_in_tileset = true
	var dictionary_bookmark_1 = _current_dictionary
	var array_bookmark_1 = _current_array
	err = simple_element(element_name, attribs)
	var base_element = _current_element
	var base_group_level = _current_group_level
	while err == OK and (not _xml.is_end() or _current_element != base_element or
			(base_element == "group" and _current_element == "group" and _current_group_level == base_group_level)):
		_current_element = _xml.next_element()
		if _current_element == null:
			return ERR_PARSE_ERROR
		if _xml.is_end():
			if _current_element == "group":
				_current_group_level -= 1
			if _current_element == "properties":
				_current_properties_level -= 1
			continue
		if _current_element == "group" and not _xml.is_empty():
			_current_group_level += 1
		if _current_element == "properties" and not _xml.is_empty():
			_current_properties_level += 1
		if _current_element == "<data>":
			var data = _xml.get_data()
			if base_element == "text":
				_current_dictionary[base_element] = str(data).replace("\r", "");
			elif base_element == "property":
				_current_array[-1]["value"] = str(data).replace("\r", "");
			else:
				data = data.strip_edges(true, true)
				if _csv_encoded:
					var arr = []
					for s in data.split(','):
						arr.append(int(s.strip_edges(true, true)))
					data = arr
				_current_array[-1]["data"] = data
			continue
		var c_attributes = _xml.get_attributes()
		var dictionary_bookmark_2 = _current_dictionary
		var array_bookmark_2 = _current_array
		if _xml.is_empty():
			err = simple_element(_current_element, c_attributes)
		else:
			err = nested_element(_current_element, c_attributes)
		_current_dictionary = dictionary_bookmark_2
		_current_array = array_bookmark_2

	_current_dictionary = dictionary_bookmark_1
	_current_array = array_bookmark_1
	if base_element == "tileset":
		_in_tileset = false
	return err
	
func insert_attributes(target_dictionary: Dictionary, attribs: Dictionary, no_name: bool = false):
	for key in attribs:
		if no_name and key == "name":
			continue
		var attr_val: Variant
		if key == "infinite":
			attr_val = attribs[key] == "1"
		elif key == "visible":
			attr_val = attribs[key] == "1"
		elif key == "wrap":
			attr_val = attribs[key] == "1"
		else:
			attr_val = attribs[key]
		
		if "version" not in key:
			if str(attr_val).is_valid_int():
				attr_val = int(attr_val)
			elif str(attr_val).is_valid_float():
				attr_val = float(attr_val)

		target_dictionary[key] = attr_val

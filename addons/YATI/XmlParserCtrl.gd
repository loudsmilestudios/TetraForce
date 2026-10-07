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

var _parser = null
var _parsed_file_name = ""

func _init():
	_parser = XMLParser.new()

func open(tiled_file_content: PackedByteArray, source_file) -> int:
	_parsed_file_name = source_file
	return _parser.open_buffer(tiled_file_content)

func next_element():
	var err = parse_on()
	if err != OK:
		return null
	if _parser.get_node_type() == XMLParser.NODE_TEXT:
		var text = _parser.get_node_data().strip_edges(true, true)
		if text.length() > 0:
			return "<data>"
	while _parser.get_node_type() != XMLParser.NODE_ELEMENT and _parser.get_node_type() != XMLParser.NODE_ELEMENT_END:
		err = parse_on()
		if err != OK:
			return null
	return _parser.get_node_name()

func is_end() -> bool:
	return _parser.get_node_type() == XMLParser.NODE_ELEMENT_END

func is_empty() -> bool:
	return _parser.is_empty()

func get_data() -> String:
	return _parser.get_node_data()

func get_attributes() -> Dictionary:
	var attributes = {}
	for i in range(_parser.get_attribute_count()):
		attributes[_parser.get_attribute_name(i)] = _parser.get_attribute_value(i)
	return attributes

func parse_on() -> int:
	var err = _parser.read()
	if err != OK:
		printerr("Error parsing file '" + _parsed_file_name + "' (around line " + str(_parser.get_current_line()) + ").")
	return err

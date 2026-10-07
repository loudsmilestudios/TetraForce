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

var _error: Error = OK

func get_error():
    return _error

func call_post_process(base_node: Node2D, path: String):
    var script = load(path)
    if script == null or not script is GDScript:
        printerr("Script could not be properly recognized/loaded. -> Postprocessing skipped")
        _error = ERR_FILE_UNRECOGNIZED
        return base_node
    var script_obj = script.new()
    if script_obj == null:
        printerr("Script could not be instanciated. -> Postprocessing skipped")
        _error = ERR_SCRIPT_FAILED
        return base_node
    if not script_obj.has_method("_post_process"):
        printerr("Script has no method '_post_process'. -> Postprocessing skipped")
        _error = ERR_METHOD_NOT_FOUND
        return base_node
    var returned_node = script_obj._post_process(base_node)
    if returned_node == null or not returned_node is Node2D:
        printerr("Script returned invalid data. -> Postprocessing skipped")
        _error = ERR_INVALID_DATA
        return base_node
    return returned_node
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
class_name CustomTypes

extends RefCounted

var _custom_types = null

func load_custom_types(project_file: String):
    var proj_file_content = DataLoader.get_tiled_file_content(project_file, "")
    if proj_file_content == null:
        printerr("ERROR: Tiled project file '" + project_file + "' not found.")
        CommonUtils.error_count += 1
        return

    var project_file_as_dictionary: Dictionary = preload("DictionaryBuilder.gd").new().get_dictionary(proj_file_content, project_file)
    if project_file_as_dictionary.has("propertyTypes"):
        _custom_types = project_file_as_dictionary["propertyTypes"]


func unload_custom_types():
    _custom_types.clear()


func merge_custom_properties(obj: Dictionary, scope: String):
    if _custom_types == null: return
    
    var class_string = obj.get("class", "")
    if class_string == "":
        class_string = obj.get("type", "")
    
    var properties: Array
    var new_key = false
    if obj.has("properties"):
        properties = obj["properties"]
    else:
        properties = []
        new_key = true

    for ct_prop in _custom_types:
        var pt_name = ct_prop.get("name", "")
        var pt_type = ct_prop.get("type", "")
        var pt_scope: Array = ct_prop.get("useAs", [])
        if pt_name != class_string or pt_type != "class" or not pt_scope.has(scope): continue
        var pt_members: Array = ct_prop.get("members", [])
        for mem in pt_members:
            var name = mem.get("name", "")
            var append = true
            for prop in properties:
                if name == prop.get("name", ""):
                    append = false
                    break
            if not append: continue
            if new_key:
                obj["properties"] = []
                new_key = false
            obj["properties"].append(mem)

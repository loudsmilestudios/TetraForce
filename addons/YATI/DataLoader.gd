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
class_name DataLoader

static func get_tiled_file_content(file_name: String, base_path: String):
    var checked_file = file_name
    if not FileAccess.file_exists(checked_file):
        checked_file = base_path.path_join(file_name)
    if not FileAccess.file_exists(checked_file): return null

    var file = FileAccess.open(checked_file, FileAccess.ModeFlags.READ)
    var ret = file.get_buffer(file.get_length())
    return ret

static func load_image(file_name: String, base_path: String):
    var checked_file = file_name
    if not FileAccess.file_exists(checked_file):
        checked_file = base_path.path_join(file_name)
    if not FileAccess.file_exists(checked_file):
        printerr("ERROR: Image file '" + file_name + "' not found.")
        CommonUtils.error_count += 1
        return null

    var exists = ResourceLoader.exists(checked_file, "Image")
    if exists:
        return ResourceLoader.load(checked_file)

    var image = Image.load_from_file(checked_file)
    return ImageTexture.create_from_image(image)

static func load_resource_from_file(resource_file: String, base_path: String):
    var checked_file = resource_file
    if not FileAccess.file_exists(checked_file):
        checked_file = base_path.path_join(resource_file)
    if FileAccess.file_exists(checked_file):
        return ResourceLoader.load(checked_file)

    printerr("ERROR: Resource file '" + resource_file + "' not found.")
    CommonUtils.error_count += 1
    return null

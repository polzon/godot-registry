class_name GdFactoryTempResource
extends RefCounted

var _suite: GdUnitTestSuite
var _path: String = ""


func _init(test_suite: GdUnitTestSuite) -> void:
	assert(test_suite, "Test suite reference is null in GdFactoryTempResource.")
	_suite = test_suite


## Gets the path to the generated temp file.
func get_temp_file_path() -> String:
	return _path


func generate_temp_file(relative_path: String, file: String) -> Error:
	if not _suite:
		return ERR_UNCONFIGURED
	if relative_path.is_empty() or file.is_empty():
		return ERR_INVALID_PARAMETER

	var sanitized_file := FileSanitizer.sanitize(
		"%s/%s" % [relative_path, file]
	)
	var separator_idx := sanitized_file.rfind("/")
	if separator_idx <= 0:
		return ERR_INVALID_PARAMETER

	relative_path = sanitized_file.left(separator_idx)
	file = sanitized_file.substr(separator_idx + 1)

	# Create FileAccess using GdUnitTestSuite's create_temp_file.
	var file_access := _suite.create_temp_file(relative_path, file)
	_path = file_access.get_path()
	var result := _generate_file_at_path(_path)
	if file_access:
		file_access.close()
	return result


## Creates a resource at the given path.
func _generate_file_at_path(temp_path: String) -> Error:
	# Generate resource based on file extension.
	var new_resource: Resource = null
	if temp_path.ends_with(".tscn") or temp_path.ends_with(".scn"):
		new_resource = _create_packed_scene()
	elif temp_path.ends_with(".tres") or temp_path.ends_with(".res"):
		new_resource = Resource.new()

	if not new_resource:
		push_error("Generated PackedScene is null.")
		return FAILED

	var save_result := ResourceSaver.save(new_resource, temp_path)
	if save_result != OK:
		push_error(
			"Failed to save PackedScene to path: %s " % temp_path,
			"Error: %s" % error_string(save_result)
		)
	return save_result


## Generates and returns a simple PackedScene resource.
static func _create_packed_scene() -> PackedScene:
	var packed_scene := PackedScene.new()
	var source_scene := Node.new()

	var pack_result := packed_scene.pack(source_scene)
	if pack_result != OK:
		push_error(
			"Failed to pack the generated scene. ",
			"Error: %s" % error_string(pack_result)
		)

	source_scene.free()
	return packed_scene

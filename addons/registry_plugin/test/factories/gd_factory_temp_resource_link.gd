class_name GdFactoryTempResourceLink
extends GdFactoryTempResource

var _resource_link_path: String = ""


func get_resource_link_path() -> String:
	return _resource_link_path


func generate_temp_resource_link(
	relative_path: String, file: String
) -> ResourceLink:
	generate_temp_file(relative_path, file)
	var link := ResourceLink.create_from(get_temp_file_path())
	assert(
		link != null,
		"Failed to create ResourceLink from path: " + get_temp_file_path()
	)
	return link


func _serialize_temp_file_to_resource_link(
	relative_path: String, file: String
) -> void:
	assert(ResourceLink.exists(_path))
	var link := ResourceLink.create_from(_path)
	assert(
		link.is_valid(),
		"Failed to create valid ResourceLink from path: %s" % _path
	)

	_resource_link_path = relative_path + "/" + file + ".reslink"
	var error := ResourceSaver.save(link, _resource_link_path)
	assert(
		error == OK,
		(
			"Failed to save ResourceLink to path: %s. Error code: %d"
			% [_resource_link_path, error]
		)
	)

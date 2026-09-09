class_name ResourceLinkLoaderID
extends ResourceLinkLoader

const INVALID_UID_INT: int = -1


static func create_from_id(id: int) -> ResourceLink:
	var link := ResourceLink.new()
	if is_id(id):
		link.res_path = to_path(id)
		link.res_uid = to_uid(id)
		link.res_id = id
	return link


static func load_id(id: int, type_hint: String, cache_mode: int) -> Resource:
	if id_exists(id):
		var uid_or_path := ResourceUID.get_id_path(id)
		return ResourceLoader.load(uid_or_path, type_hint, cache_mode)

	push_error("ResourceLink: Failed to load resource with ID: ", id)
	return null


static func to_id(path_or_uid: Variant) -> int:
	if path_or_uid is String:
		var value_str: String = path_or_uid
		if is_path(value_str):
			# If it's a valid path with a registered UID.
			var existing_id := ResourceLoader.get_resource_uid(value_str)
			if existing_id != INVALID_UID_INT:
				return existing_id

			# If it's valid path without a registered UID, we will create one.
			return get_or_create_id_for_path(value_str)

		if is_uid(value_str):
			return ResourceUID.text_to_id(value_str)

		if is_id(value_str):
			var str_to_id := value_str.to_int()
			return _add_and_return_id(value_str, str_to_id)

	if path_or_uid is int:
		return path_or_uid

	return INVALID_UID_INT


static func is_id(value: Variant) -> bool:
	if value is String:
		var value_str: String = value
		if not value_str.contains("://"):
			var str_to_int := value_str.to_int()
			return id_exists(str_to_int)

	if value is int:
		var value_int: int = value
		return id_exists(value_int)

	return false


static func id_exists(id: int) -> bool:
	return id != INVALID_UID_INT and ResourceUID.has_id(id)


## Adds an ID to the ResourceUID registry if neccesary, and returns the ID.
static func _add_and_return_id(path: String, id: int) -> int:
	if not ResourceUID.has_id(id):
		ResourceUID.add_id(id, path)
	return id

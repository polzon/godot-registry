class_name ResourceLinkLoaderPath
extends ResourceLinkLoader

const PATH_PREFIX: String = "res://"
const INVALID_PATH: String = ""


static func create_from_path(path_or_uid: Variant) -> ResourceLink:
	if path_or_uid is String:
		var value_str: String = path_or_uid
		var link := ResourceLink.new()
		if path_exists(value_str):
			link.res_path = value_str
			link.res_uid = to_uid(value_str)
			link.res_id = to_id(value_str)
		return link
	return ResourceLink.new()


static func load_path(
	path: String, type_hint: String, cache_mode: int
) -> Resource:
	if path_exists(path):
		return ResourceLoader.load(path, type_hint, cache_mode)

	push_warning(
		"ResourceLink: Failed to load resource with path: ",
		path,
	)
	return null


static func is_path(path_or_uid: Variant) -> bool:
	if path_or_uid is String:
		var path_or_uid_str: String = path_or_uid
		if (
			path_or_uid_str.contains("://")
			and not path_or_uid_str.begins_with("uid://")
		):
			return true
		return path_exists(path_or_uid_str, "")
	return false


static func path_exists(path: String, type_hint := "") -> bool:
	if ResourceLoader.exists(path, type_hint):
		return true

	if path.begins_with("user://") and FileAccess.file_exists(path):
		if type_hint.is_empty():
			return true
		var loaded_resource := ResourceLoader.load(path, type_hint)
		return loaded_resource != null

	return false


static func to_path(uid: Variant) -> String:
	if uid is String:
		var uid_str: String = uid
		## If it's a UID string, convert to path.
		if is_uid(uid_str):
			return ResourceUID.uid_to_path(uid_str)

		# If it's a UID integer, but in string format.
		if is_uid(uid_str):
			var uid_int := uid_str.to_int()
			if ResourceUID.has_id(uid_int):
				return ResourceUID.get_id_path(uid_int)

		## If it's not a UID string, and it has a valid path, it must be a path.
		if path_exists(uid_str):
			return uid_str

	# If it's a integer UID, just convert to path.
	if uid is int:
		var uid_int: int = uid
		if ResourceUID.has_id(uid_int):
			return ResourceUID.get_id_path(uid_int)
	return INVALID_PATH

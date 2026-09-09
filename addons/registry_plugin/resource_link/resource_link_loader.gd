class_name ResourceLinkLoader

# TODO: Add a "quirk" checker for handling edge cases.
# - Such as corrupt and missing UIDs.
# - Web builds don't seem to like direct paths for example.
# - Can add a "strict" mode that requires all paths and ids to be valid.

static var _supress_warnings: bool = false

## Maps a path with no persisted UID to the UID string synthesized for it, so
## repeated lookups return the same value instead of a fresh random one.
static var _synthesized_uids: Dictionary[String, String] = {}


## Returns a stable UID string for a path that has no persisted UID, reusing
## the same value for the lifetime of the session.
static func get_or_create_uid_for_path(path: String) -> String:
	if _synthesized_uids.has(path):
		return _synthesized_uids[path]
	var uid_int := ResourceUID.create_id_for_path(path)
	if not ResourceUID.has_id(uid_int):
		ResourceUID.add_id(uid_int, path)
	var uid_str := ResourceUID.id_to_text(uid_int)
	_synthesized_uids[path] = uid_str
	return uid_str


## Returns a stable UID integer for a path that has no persisted UID, matching
## [method get_or_create_uid_for_path].
static func get_or_create_id_for_path(path: String) -> int:
	return ResourceUID.text_to_id(get_or_create_uid_for_path(path))


static func load_resource(
	link: ResourceLink, type: String, cache: int
) -> Resource:
	if path_exists(link.res_path):
		return ResourceLinkLoaderPath.load_path(link.res_path, type, cache)
	if uid_exists(link.res_uid):
		return ResourceLinkLoaderUID.load_uid(link.res_uid, type, cache)
	if id_exists(link.res_id):
		return ResourceLinkLoaderID.load_id(link.res_id, type, cache)

	if not _supress_warnings:
		push_warning("ResourceLink: Failed to load resource ", link)
	return null


static func create_from_path(path: String) -> ResourceLink:
	return ResourceLinkLoaderPath.create_from_path(path)


static func create_from_uid(uid: String) -> ResourceLink:
	return ResourceLinkLoaderUID.create_from_uid(uid)


static func create_from_id(id: int) -> ResourceLink:
	return ResourceLinkLoaderID.create_from_id(id)


static func to_path(value: Variant) -> String:
	return ResourceLinkLoaderPath.to_path(value)


static func to_id(value: Variant) -> int:
	return ResourceLinkLoaderID.to_id(value)


static func to_uid(value: Variant) -> String:
	return ResourceLinkLoaderUID.to_uid(value)


static func is_path(value: Variant) -> bool:
	return ResourceLinkLoaderPath.is_path(value)


static func is_uid(value: Variant) -> bool:
	return ResourceLinkLoaderUID.is_uid(value)


static func is_id(value: Variant) -> bool:
	return ResourceLinkLoaderID.is_id(value)


static func exists(value: Variant, type_hint := "") -> bool:
	if value is String:
		var value_str: String = value
		return (
			path_exists(value_str, type_hint)
			or uid_exists(value_str, type_hint)
			or id_exists(value_str.to_int())
		)

	if value is int:
		var value_int: int = value
		return id_exists(value_int)

	if not _supress_warnings:
		push_warning("ResourceLink: Unrecognized value for path: ", value)
	return false


static func path_exists(path: String, type_hint := "") -> bool:
	return ResourceLinkLoaderPath.path_exists(path, type_hint)


static func uid_exists(uid: String, type_hint := "") -> bool:
	return ResourceLinkLoaderUID.uid_exists(uid, type_hint)


static func id_exists(id: int) -> bool:
	return ResourceLinkLoaderID.id_exists(id)

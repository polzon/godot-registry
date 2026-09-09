class_name ResourceLinkLoaderUID
extends ResourceLinkLoader

const UID_PREFIX: String = "uid://"
const INVALID_UID_POSTFIX: String = "<invalid>"
const INVALID_UID_STR: String = UID_PREFIX + INVALID_UID_POSTFIX


static func create_from_uid(uid: String) -> ResourceLink:
	var link := ResourceLink.new()
	if is_uid(uid):
		link.res_path = to_path(uid)
		link.res_uid = uid
		link.res_id = to_id(uid)
	return link


static func load_uid(
	uid: String, type_hint: String, cache_mode: int
) -> Resource:
	if uid_exists(uid):
		return ResourceLoader.load(uid, type_hint, cache_mode)

	push_warning(
		"ResourceLink: Failed to load resource with UID: ",
		uid,
	)
	return null


static func is_uid(uid: Variant) -> bool:
	if uid is not String:
		return false

	var uid_str: String = uid
	return (
		uid_str.contains(UID_PREFIX)
		and not uid_str.contains(INVALID_UID_POSTFIX)
	)


static func uid_exists(uid: String, type_hint := "") -> bool:
	return ResourceLoader.exists(uid, type_hint)


static func to_uid(uid: Variant) -> String:
	if uid is int:
		var uid_int: int = uid
		if ResourceUID.has_id(uid_int):
			return ResourceUID.id_to_text(uid_int)

	if uid is String:
		# Is already a valid UID string.
		var uid_str: String = uid
		if is_uid(uid_str):
			return uid_str

		# Is a valid path.
		if is_path(uid_str):
			var path_to_uid_str := ResourceUID.path_to_uid(uid_str)
			if path_to_uid_str != uid_str:
				return path_to_uid_str

			# Is valid path without a registered UID.
			return get_or_create_uid_for_path(uid_str)

	return INVALID_UID_STR

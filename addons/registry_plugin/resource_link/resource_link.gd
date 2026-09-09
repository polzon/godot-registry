@tool
class_name ResourceLink
extends Resource
## Resiliant data container that tracks a Resource file location.
##
## Internally stores the UID in int *and* string format, as well as the relative
## file path. When any of these values are corrupted (such as a file moved),
## the other data will be used to rebuild these links.

# TODO: We could detect type data from the resource and store for more data.
#       - Can also be used as a type hint for ResourceLoader.
# ? Should we create a ResourceLoaderFormat for this format?

## Supresses warnings during tests.
static var _supress_warnings: bool = false:
	set = _set_supress_warnings

## Resource relative file path. E.g. [code]res://scenes/level1.tscn[/code].
@export_file("*.tscn", "*.res") var res_path: String
## Resource UID in string format. E.g. [code]uid://1234567890abcdef[/code].
@export_storage var res_uid: String = ResourceLinkLoaderUID.INVALID_UID_STR
## Resource UID in integer format. E.g. [code]1234567890[/code].
@export_storage var res_id: int = ResourceLinkLoaderID.INVALID_UID_INT


static func create_from(value: Variant) -> ResourceLink:
	if value is String:
		var value_str: String = value
		if ResourceLinkLoader.is_path(value_str):
			return ResourceLinkLoader.create_from_path(value_str)
		if ResourceLinkLoader.is_uid(value_str):
			return ResourceLinkLoader.create_from_uid(value_str)
		if ResourceLinkLoader.is_id(value_str):
			return ResourceLinkLoader.create_from_id(value_str.to_int())

	if value is int:
		var value_int: int = value
		return ResourceLinkLoader.create_from_id(value_int)

	if not _supress_warnings and not Engine.is_editor_hint():
		push_error(
			"ResourceLink: Failed to create ResourceLink from value: ", value
		)
	return ResourceLink.new()


func is_valid() -> bool:
	return has_valid_path() or has_valid_uid() or has_valid_id()


func has_valid_path() -> bool:
	return ResourceLinkLoader.path_exists(res_path)


func has_valid_uid() -> bool:
	return ResourceLinkLoader.is_uid(res_uid)


func has_valid_id() -> bool:
	return ResourceLinkLoader.id_exists(res_id)


static func exists(value: Variant, type_hint := "") -> bool:
	return ResourceLinkLoader.exists(value, type_hint)


## Alias for [code]ResourceLink.exists(value, "PackedScene")[/code].
static func scene_exists(value: Variant) -> bool:
	var does_exist := ResourceLinkLoader.exists(value, "PackedScene")
	if (
		not does_exist
		and ResourceLinkLoader.exists(value)
		and not _supress_warnings
		and not Engine.is_editor_hint()
	):
		push_error(
			"ResourceLink: Resource exists but is not a PackedScene: ", value
		)
	return does_exist


static func load(
	path: String, type_hint := "", cache_mode: int = 1
) -> Resource:
	return create_from(path).load_resource(type_hint, cache_mode)


## Alias for [code]ResourceLink.load(value, "PackedScene")[/code].
static func load_scene(path_or_uid: String, cache_mode: int = 1) -> PackedScene:
	var scene: PackedScene = ResourceLink.load(
		path_or_uid, "PackedScene", cache_mode
	)
	if not scene and not _supress_warnings and not Engine.is_editor_hint():
		if ResourceLinkLoader.exists(path_or_uid):
			push_error(
				"ResourceLink: Resource failed to load as a PackedScene: ",
				path_or_uid
			)
		else:
			push_error(
				"ResourceLink: Failed to load PackedScene: ", path_or_uid
			)
	return scene


## Tries to load the [Resource] in the first possible way. It tries in order of
## path, uid string, and then uid int.
func load_resource(type_hint := "", cache_mode: int = 1) -> Resource:
	return ResourceLinkLoader.load_resource(self, type_hint, cache_mode)


## Checks it the project setting for binary export is enabled.
##
## This is relevant because if enabled, the [ResourceLoader] will convert
## text-based resources to binary format, which can cause the resource to fail
## to load.[br]
## See the relevant docs for [method ResourceLoader.load] for more details.
static func check_if_binary_export_enabled() -> bool:
	const BINARY_SETTING := "editor/export/convert_text_resources_to_binary"
	return ProjectSettings.get_setting(BINARY_SETTING, true)


static func _set_supress_warnings(enabled: bool) -> void:
	_supress_warnings = enabled
	ResourceLinkLoader._supress_warnings = enabled


## Returns true if both links point at the same file location. This is the
## fast path for comparison and ignores UID drift.
func is_same_location(other: ResourceLink) -> bool:
	if not other:
		return false
	if not res_path.is_empty() and res_path == other.res_path:
		return true
	return (
		not res_path.is_empty()
		and not other.res_path.is_empty()
		and (
			ResourceLinkLoader.to_path(res_path)
			== ResourceLinkLoader.to_path(other.res_path)
		)
	)


## Returns true if both links match on path, UID string, and UID integer.
## Strict comparison used when full fidelity is required.
func deep_compare(other: ResourceLink) -> bool:
	if not other:
		return false
	return (
		res_path == other.res_path
		and res_uid == other.res_uid
		and res_id == other.res_id
	)


## Returns true if both links point at the same file, preferring the fast
## location check and falling back to a strict deep compare when paths differ.
func is_equivalent_to(other: ResourceLink) -> bool:
	if is_same_location(other):
		return true
	return deep_compare(other)

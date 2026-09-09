# DEPRECATED: Use Registry.entries (Dictionary[StringName, ResourceLink])
# instead. This class will be removed in a future cleanup.
class_name LinkRegistry
extends Resource
## Registry resource for tracking [ResourceLink] files. Translates a human
## readable name to a [ResourceLink].

# NOTES:
#
# Not sure if we should store the human readable name in here as a key, or if
# it should be an export variable on the ResourceLink.
#   - If we store it in here, we can treat the LinkRegistry as a namespace.
#   - However, if the LinkRegistry corrupts, we lose all data.
#   - If we store it on the ResourceLink, we can use that data to
#     rebuild registries.
#     - However, I'm unsure how we should handle ResourceLinks without a human
#       readable name.
#     - Also what that would look like for the API.
#     - This however would be the more resilient option, but not work with
#       namespaces.
#   - We could possibly do both and store the data redundantly. It's very cheap
#     data and can be used to restore data on either side.
#     - Is data corruption really a concern to worry about?
#
# Multiple registries will exist, they will work like a local index. We will not
# treat this as a Singleton or global registry.
#   - We can however, still have a global registry that loads local LinkRegsitry
#     data and serves as a global index.

## If true, the registry will read only during runtime. This can be set to false
## to disable this behavior, or re-enabled at runtime using
## [method set_read_only(true)].
const READ_ONLY_OUTSIDE_EDITOR: bool = true

## Dictionary mapping human readable names to ResourceLink objects.
@export_storage var _link_db: Dictionary[StringName, ResourceLink] = {}

var _is_read_only: bool = false:
	set = set_read_only


func _init() -> void:
	_is_read_only = READ_ONLY_OUTSIDE_EDITOR and not Engine.is_editor_hint()


## Adds a [ResourceLink] to the registry with a human readable name, only if
## that name doesn't already exist in the registry. Returns true if successful,
## and false if that name already exists in the registry.
func add_link(name: StringName, link: ResourceLink) -> bool:
	if not _link_db.has(name):
		_link_db[name] = link
		return true
	return false


## Sets a [ResourceLink] in the registry with a human readable name,
## overwriting any existing entry with that name.
func set_link(name: StringName, link: ResourceLink) -> void:
	_link_db[name] = link


## Creates a [ResourceLink] from a path or UID and adds it to the registry with
## a human readable name, only if that name doesn't already exist in the
## registry.
func create_link(name: StringName, path_or_uid: Variant) -> ResourceLink:
	var link := ResourceLink.create_from(path_or_uid)
	add_link(name, link)
	return link


func delete_link(name: StringName) -> bool:
	return _link_db.erase(name)


func get_link(name: StringName) -> ResourceLink:
	return _link_db.get(name, null)


func load_link(name: StringName) -> Resource:
	var link := get_link(name)
	return link.load_resource() if link else null


func set_read_only(enabled: bool) -> void:
	_is_read_only = enabled
	if _is_read_only and not _link_db.is_read_only():
		_link_db.make_read_only()
	elif not _is_read_only and _link_db.is_read_only():
		_link_db = _link_db.duplicate()

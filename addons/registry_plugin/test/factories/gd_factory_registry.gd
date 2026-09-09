class_name GdFactoryRegistry
extends RefCounted
## Builds a [Registry] and its on-disk entries and tags for registry tests.

const TAGS_SUBDIR := "tags"
const NAME_PROPERTY := &"entry_name"

var _root: String
var _scan_dir: String


func _init(root: String, scan_dir: String = "") -> void:
	_root = root
	_scan_dir = scan_dir if not scan_dir.is_empty() else root


## Returns a configured Registry whose scan_path defaults to the scan dir.
func make_registry(
	registry_name: String,
	scan_path: String = "",
	entry_type: GDScript = TestRegistryEntry,
	name_property: StringName = NAME_PROPERTY,
) -> Registry:
	var registry := Registry.new()
	registry.registry_name = registry_name
	registry.scan_path = scan_path if not scan_path.is_empty() else _scan_dir
	registry.entry_type = entry_type
	registry.name_property = name_property
	return registry


## Saves a TestRegistryEntry into the scan dir and returns its path.
func save_entry(
	file_name: String, entry_name: String, category: String = ""
) -> String:
	var entry := TestRegistryEntry.new()
	entry.entry_name = entry_name
	entry.category = category
	return _save_resource(entry, _scan_dir, file_name)


## Saves a plain Resource into the scan dir and returns its path.
func save_plain(file_name: String) -> String:
	return _save_resource(Resource.new(), _scan_dir, file_name)


## Saves a RegistryTag under the scan dir's tags/ subfolder.
func save_tag(tag_name: String, entry_names: Array[String]) -> void:
	var tag := RegistryTag.new()
	tag.tag_name = tag_name
	tag.entry_names = PackedStringArray(entry_names)
	var tags_dir := _scan_dir.path_join(TAGS_SUBDIR)
	DirAccess.make_dir_recursive_absolute(tags_dir)
	_save_resource(tag, tags_dir, "%s.tres" % tag_name)


## Saves a Registry into the root and returns its path.
func save_registry(registry: Registry, file_name: String) -> String:
	return _save_resource(registry, _root, file_name)


func _save_resource(
	resource: Resource, dir: String, file_name: String
) -> String:
	var path := dir.path_join(file_name)
	var error := ResourceSaver.save(resource, path)
	assert(error == OK, "Failed to save %s: %s" % [path, error_string(error)])
	return path

class_name GdFactoryRegistryIndex
extends RefCounted
## Builds a full on-disk registry index for index-build and runtime-load tests.

const NAME_PROPERTY := &"entry_name"
const ENTRIES_DIR := "entries"

var _project_root: String
var _entries_dir: String


func _init(project_root: String) -> void:
	_project_root = project_root
	_entries_dir = project_root.path_join(ENTRIES_DIR)
	DirAccess.make_dir_recursive_absolute(_entries_dir)


## Returns the directory that holds scanned entry files.
func get_entries_dir() -> String:
	return _entries_dir


## Saves a TestRegistryEntry into the entries dir and returns its path.
func save_entry(file_name: String, entry_name: String) -> String:
	var entry := TestRegistryEntry.new()
	entry.entry_name = entry_name
	return _save_resource(entry, _entries_dir, file_name)


## Returns a Registry configured to scan the entries dir.
func make_registry(registry_name: String) -> Registry:
	var registry := Registry.new()
	registry.registry_name = registry_name
	registry.scan_path = _entries_dir
	registry.entry_type = TestRegistryEntry
	registry.name_property = NAME_PROPERTY
	return registry


## Saves a Registry into the project root and returns its path.
func save_registry(
	registry: Registry, file_name: String = "tiles.tres"
) -> String:
	return _save_resource(registry, _project_root, file_name)


## Builds the index file and returns its path.
func build_index(output: String = "registry_index.tres") -> String:
	var output_path := _project_root.path_join(output)
	var updated := RegistryIndexLoader.update_index(
		[], _project_root, output_path
	)
	assert(updated == OK, "Failed to build index: %s" % error_string(updated))
	return output_path


func _save_resource(
	resource: Resource, dir: String, file_name: String
) -> String:
	var path := dir.path_join(file_name)
	var error := ResourceSaver.save(resource, path)
	assert(error == OK, "Failed to save %s: %s" % [path, error_string(error)])
	return path

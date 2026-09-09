@tool
class_name RegistryIndex
extends Resource
## Resource file that holds links to all [Registry] resources in the project.

const TILES := &"tiles"

static var _instance: RegistryIndex:
	get = _get_instance

@export var registry_paths: Dictionary[StringName, Variant] = {}


static func find(
	registry_name: StringName, entry_name: StringName = &""
) -> Variant:
	var registry := get_registry(registry_name)
	if not registry:
		return null
	if not entry_name.is_empty():
		return registry.get_entry(entry_name)
	return registry


static func set_registry(registry_name: StringName, registry: Registry) -> void:
	if _instance:
		_instance.registry_paths[registry_name] = registry


static func get_registry(registry_name: StringName) -> Registry:
	var index := _instance
	if not index or not index.registry_paths.has(registry_name):
		return null
	var registry: Registry = index.registry_paths[registry_name]
	assert(registry, "Failed to load registry '%s' from index" % registry_name)
	return registry


static func snapshot() -> Dictionary[StringName, Variant]:
	if not _instance:
		return {}
	return _instance.registry_paths.duplicate()


static func restore(paths: Dictionary[StringName, Variant]) -> void:
	if not _instance:
		return
	_instance.registry_paths = paths.duplicate()


## Clears the cached instance so the next access reloads from disk.
static func reset() -> void:
	_instance = null


static func _get_instance() -> RegistryIndex:
	if _instance == null:
		_instance = RegistryIndexLoader.load_index()
	return _instance


func build(excluded_dirs: Array[String] = [], root: String = "res://") -> void:
	var paths := search_registry_paths(root, excluded_dirs)

	registry_paths.clear()
	for path in paths:
		var resource := ResourceLoader.load(path)
		if resource is Registry:
			var registry := resource as Registry
			registry.scan()
			registry_paths[registry.registry_name] = registry
			_save_registry_if_changed(path, registry)


## Saves the registry only when the file is missing or its content changed,
## so unrelated filesystem events do not rewrite it. The on-disk copy is read
## without the cache because the scanned registry is the same cached object.
static func _save_registry_if_changed(path: String, registry: Registry) -> void:
	if ResourceLoader.exists(path):
		var existing := (
			ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
			as Registry
		)
		if existing and existing.is_equivalent_to(registry):
			return
	_save_registry(path, registry)


static func _save_registry(path: String, registry: Registry) -> void:
	var error := ResourceSaver.save(registry, path)
	if error != OK:
		push_error(
			"Failed to save registry '%s' " % registry.registry_name,
			"to %s: %s" % [path, error_string(error)]
		)


static func search_registry_paths(
	root: String = "res://", excluded_dirs: Array[String] = []
) -> Array[String]:
	return RegistryUtilScanner.find_resource_paths(
		root, is_resource_index, excluded_dirs
	)


static func is_supported_extension(entry_path: String) -> bool:
	return RegistryUtilScanner.is_supported_extension(entry_path)


## A registry index file is any file whose script class is [Registry].
static func is_resource_index(
	script_class: String, _resource_type: String
) -> bool:
	return script_class == "Registry"


# --- Tag bridge methods (replace TileTagRegistry / TileDB) ---


## Returns true if [param tag_name] is registered in [param registry_name].
static func has_tag(registry_name: StringName, tag_name: StringName) -> bool:
	var registry := get_registry(registry_name)
	if not registry:
		return false
	return registry.tags.has(tag_name)


## Returns all tag names in [param registry_name].
static func all_tag_names(registry_name: StringName) -> PackedStringArray:
	var registry := get_registry(registry_name)
	if not registry:
		return PackedStringArray()
	return registry.tags.keys().duplicate()


## Returns a comma-joined hint string for PROPERTY_HINT_ENUM.
static func enum_hint_string(registry_name: StringName) -> String:
	return ",".join(all_tag_names(registry_name))


## Returns every entry matching [param tag_name] in [param registry_name].
static func find_by_tag(
	registry_name: StringName, tag_name: StringName
) -> Array[Resource]:
	var registry := get_registry(registry_name)
	if not registry:
		return []

	var entry_names := registry.entries_in_tag(tag_name)
	var results: Array[Resource] = []
	for entry_name: String in entry_names:
		if entry_name.is_empty():
			push_error(
				(
					"Registry '%s': failed to load entry '%s'"
					% [registry_name, entry_name]
				)
			)
			continue

		var entry: Variant = registry.get_entry(entry_name)
		if entry:
			results.append(entry)

		else:
			push_error(
				(
					"Failed to load entry '%s' in registry '%s'"
					% [entry_name, registry_name]
				)
			)
	return results


## Returns true if any entry in [param registry_name] carries [param tag_name].
static func has_entry_with_tag(
	registry_name: StringName, tag_name: StringName
) -> bool:
	var registry := get_registry(registry_name)
	if not registry:
		return false
	return registry.tags.has(tag_name)


## Returns the first entry matching [param tag_name], or null.
static func find_first_by_tag(
	registry_name: StringName, tag_name: StringName
) -> Resource:
	var matches := find_by_tag(registry_name, tag_name)
	return null if matches.is_empty() else matches[0]

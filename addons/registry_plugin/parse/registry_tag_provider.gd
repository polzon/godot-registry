@tool
class_name RegistryTagProvider
## Static utility that resolves tag names and [RegistryTag] resources by
## scanning [Registry] resources on disk, so new tags appear without
## rebuilding the prebuilt index.

const TAGS_SUBDIR := "tags"


## Returns every tag name registered in [param registry_name], sorted for a
## stable dropdown, or an empty list when the registry is not found.
static func get_tag_list(
	registry_name: StringName, root: String = "res://"
) -> PackedStringArray:
	var registry := _find_registry(registry_name, root)
	if not registry:
		return PackedStringArray()
	registry.scan()
	return RegistryUtilScanner.sorted_string_names(registry.tags.keys())


## Returns a comma-joined hint string for PROPERTY_HINT_ENUM.
static func hint_string(
	registry_name: StringName, root: String = "res://"
) -> String:
	return ",".join(get_tag_list(registry_name, root))


## Resolves [param value] to a [RegistryTag]. Accepts a [RegistryTag], or a
## [String]/[StringName] tag name found in any registry under [param root].
## Returns null when the value is null, empty, or not a known tag.
static func variant_to_tag(
	value: Variant, root: String = "res://"
) -> RegistryTag:
	if value == null:
		return null
	if value is RegistryTag:
		return value
	if value is String or value is StringName:
		var tag_name: StringName = value
		if not tag_name.is_empty():
			return _find_tag(tag_name, root)
	return null


static func _find_registry(registry_name: StringName, root: String) -> Registry:
	for registry in _registries(root):
		if registry.registry_name == registry_name:
			return registry
	return null


static func _find_tag(tag_name: StringName, root: String) -> RegistryTag:
	for registry in _registries(root):
		registry.scan()
		if not registry.tags.has(tag_name):
			continue
		var tag := _load_tag(registry, tag_name)
		if tag:
			return tag
	return null


static func _load_tag(registry: Registry, tag_name: StringName) -> RegistryTag:
	var tags_dir := registry.scan_path.path_join(TAGS_SUBDIR)
	if not DirAccess.dir_exists_absolute(tags_dir):
		return null
	var tag_paths := RegistryUtilScanner.find_resource_paths(
		tags_dir,
		func(script_class: String, _resource_type: String) -> bool:
			return script_class == "RegistryTag"
	)
	for path in tag_paths:
		var tag := ResourceLoader.load(path) as RegistryTag
		if tag and tag.tag_name == tag_name:
			return tag
	return null


static func _registries(root: String) -> Array[Registry]:
	var registries: Array[Registry] = []
	for path in _registry_paths(root):
		var registry := (
			ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
			as Registry
		)
		if registry:
			registries.append(registry)
	return registries


static func _registry_paths(root: String) -> Array[String]:
	return RegistryUtilScanner.find_resource_paths(root, is_registry_resource)


## A registry resource is any file whose script class is [Registry].
static func is_registry_resource(
	script_class: String, _resource_type: String
) -> bool:
	return script_class == "Registry"

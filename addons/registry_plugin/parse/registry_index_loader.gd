@tool
class_name RegistryIndexLoader

const _REGISTRY_INDEX_FILE := "res://registry_index.tres"


## Returns true if the prebuilt registry index file exists.
static func index_exists() -> bool:
	return ResourceLoader.exists(_REGISTRY_INDEX_FILE)


## Deletes the prebuilt registry index file and clears the cached instance
## so the next access rebuilds it.
static func delete(path: String = _REGISTRY_INDEX_FILE) -> void:
	if ResourceLoader.exists(path):
		DirAccess.remove_absolute(path)
	RegistryIndex.reset()


## Updates the registry index and returns an [Error] indicating the result.
## [br]
## The [param root] and [param output_path] parameters default to the full
## project layout so production calls need no arguments.
static func update_index(
	excluded_dirs: Array[String] = [],
	root: String = "res://",
	output_path: String = _REGISTRY_INDEX_FILE
) -> Error:
	assert(
		OS.is_debug_build(), "RegistryIndex should not be rebuilt in runtime!"
	)
	var index := RegistryIndex.new()
	index.build(excluded_dirs, root)

	var err := ResourceSaver.save(index, output_path)
	if err != OK:
		push_error("Failed to save registry index: %s" % error_string(err))
		return err

	return OK


## Loads the prebuilt registry index at runtime and returns it, or null if it
## is missing.
static func load_index(path: String = _REGISTRY_INDEX_FILE) -> RegistryIndex:
	if not ResourceLoader.exists(path):
		if not OS.is_debug_build():
			push_warning(
				"Registry index file '%s' does not exist!" % path,
				"Please ensure the registry index is built in the editor."
			)
			return null
		update_index([], "res://", path)
	return ResourceLoader.load(path) as RegistryIndex

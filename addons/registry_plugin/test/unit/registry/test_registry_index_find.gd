extends GdUnitTestSuite

const TEST_DIR_NAME := "registry_find"

## [registry_name, entry_name] pairs that must resolve to a loaded resource.
const FOUND_CASES: Array[Array] = [
	[&"tiles", &"grass"],
	[&"items", &"stone_pick"],
]

## [registry_name, entry_name] pairs that must resolve to null.
const MISSING_CASES: Array[Array] = [
	[&"tiles", &"nonexistent"],
	[&"unknown", &"grass"],
]

var _temp_root: String
var _snapshot: Dictionary[StringName, Variant]


func before_test() -> void:
	clean_temp_dir()
	_temp_root = create_temp_dir(TEST_DIR_NAME)
	_snapshot = RegistryIndex.snapshot()


func after_test() -> void:
	RegistryIndex.restore(_snapshot)


func _make_registry(
	registry_name: String, entry_names: Array[String]
) -> Registry:
	var registry: Registry = auto_free(Registry.new())
	registry.registry_name = registry_name
	for entry_name: String in entry_names:
		var path := _temp_root.path_join(
			"%s_%s.tres" % [registry_name, entry_name]
		)
		var entry := Resource.new()
		assert(ResourceSaver.save(entry, path) == OK)
		registry.add_entry(entry_name, path)
	return registry


## find() dispatches to the correct registry namespace.
func test_find_dispatches_to_namespace() -> void:
	var registry_1 := _make_registry("tiles", ["grass"])
	RegistryIndex.set_registry(&"tiles", registry_1)
	var registry_2 := _make_registry("items", ["stone_pick"])
	RegistryIndex.set_registry(&"items", registry_2)

	for case: Array[StringName] in FOUND_CASES:
		var registry_name := case[0]
		var entry_name := case[1]
		var result: Variant = RegistryIndex.find(registry_name, entry_name)
		assert_object(result).is_instanceof(Resource)


## find() returns null for unknown entries and unknown registries.
func test_find_returns_null_for_missing() -> void:
	RegistryIndex.set_registry(&"tiles", _make_registry("tiles", ["grass"]))

	for case: Array[StringName] in MISSING_CASES:
		var registry_name := case[0]
		var entry_name := case[1]
		assert_object(RegistryIndex.find(registry_name, entry_name)).is_null()

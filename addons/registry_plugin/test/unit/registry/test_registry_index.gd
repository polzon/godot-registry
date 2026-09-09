extends GdUnitTestSuite

const TEST_DIR_NAME := "registry_namespace"

const TAG_REGISTRY := &"tags"
const GRASS_ENTRY := &"GRASS"

var _temp_root: String
var _registry: Registry
var _snapshot: Dictionary[StringName, Variant]


func before_test() -> void:
	clean_temp_dir()
	_temp_root = create_temp_dir(TEST_DIR_NAME)
	_registry = Registry.new()
	_snapshot = RegistryIndex.snapshot()


func after_test() -> void:
	RegistryIndex.restore(_snapshot)


func test_retrieve_registry_from_index() -> void:
	_registry.registry_name = TAG_REGISTRY
	RegistryIndex.set_registry(TAG_REGISTRY, _registry)

	var retrieved_registry := RegistryIndex.get_registry(TAG_REGISTRY)
	assert_object(retrieved_registry).is_not_null().is_instanceof(Registry)
	if not retrieved_registry:
		fail("Failed to retrieve registry '%s' from index." % TAG_REGISTRY)
		return
	assert_str(retrieved_registry.registry_name).is_equal(TAG_REGISTRY)


func test_find_entry_from_registry_namespace() -> void:
	var tag_path := _temp_root.path_join("grass.tres")
	var tag := Resource.new()
	var err := ResourceSaver.save(tag, tag_path)
	assert(err == OK)
	if err != OK:
		fail("Failed to save test tag resource: %s" % error_string(err))
		return

	_registry.registry_name = TAG_REGISTRY
	_registry.add_entry(GRASS_ENTRY, tag_path)
	RegistryIndex.set_registry(TAG_REGISTRY, _registry)

	var grass_tag: Variant = RegistryIndex.find(TAG_REGISTRY, GRASS_ENTRY)
	assert_object(grass_tag).is_not_null().is_instanceof(Resource)


## Deleting the index file forces get_registry to rebuild it on next access.
func test_registry_regenerates_after_index_deleted() -> void:
	RegistryIndexLoader.delete()
	assert_bool(RegistryIndexLoader.index_exists()).is_false()

	var registry := RegistryIndex.get_registry(&"tiles")
	assert_object(registry).is_not_null()
	assert_bool(RegistryIndexLoader.index_exists()).is_true()

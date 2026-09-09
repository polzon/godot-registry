extends GdUnitTestSuite

const TEST_DIR_NAME := "registry_runtime"
const LOAD_BUDGET_MS := 100

var _factory: GdFactoryRegistryIndex
var _project_root: String


func before_test() -> void:
	clean_temp_dir()
	_project_root = create_temp_dir(TEST_DIR_NAME)
	_factory = GdFactoryRegistryIndex.new(_project_root)


func _build_index() -> String:
	_factory.save_entry("grass.tres", "grass")
	var registry := _factory.make_registry("tiles")
	_factory.save_registry(registry)
	return _factory.build_index()


## Runtime load of the prebuilt index completes in under 100 ms.
func test_runtime_load_is_fast() -> void:
	var index_path := _build_index()

	var start := Time.get_ticks_usec()
	var index := RegistryIndexLoader.load_index(index_path)
	var elapsed_us := Time.get_ticks_usec() - start

	assert_object(index).is_not_null()
	assert_float(elapsed_us / 1000.0).is_less(LOAD_BUDGET_MS)
	var tiles: Registry = index.registry_paths.get(&"tiles")
	var grass: Variant = tiles.get_entry(&"grass")
	assert_object(grass).is_instanceof(TestRegistryEntry)

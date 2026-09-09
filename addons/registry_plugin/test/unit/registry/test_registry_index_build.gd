extends GdUnitTestSuite

const TEST_DIR_NAME := "registry_project"

var _factory: GdFactoryRegistryIndex
var _project_root: String


func before_test() -> void:
	clean_temp_dir()
	_project_root = create_temp_dir(TEST_DIR_NAME)
	_factory = GdFactoryRegistryIndex.new(_project_root)


## The full build pipeline produces a loadable index containing scanned entries
## for a temp project layout.
func test_build_pipeline_produces_index() -> void:
	_factory.save_entry("grass.tres", "grass")
	var registry := _factory.make_registry("tiles")
	_factory.save_registry(registry)

	var output := _factory.build_index()

	var loaded := ResourceLoader.load(output) as RegistryIndex
	assert_object(loaded).is_not_null()
	var tiles: Registry = loaded.registry_paths.get(&"tiles")
	assert_object(tiles).is_not_null()
	var grass: Variant = tiles.get_entry(&"grass")
	assert_object(grass).is_instanceof(TestRegistryEntry)


## Rebuilding an unchanged project must not rewrite the registry file, so
## unrelated filesystem events do not churn it.
func test_rebuild_unchanged_does_not_rewrite() -> void:
	_factory.save_entry("grass.tres", "grass")
	var registry := _factory.make_registry("tiles")
	var registry_path := _factory.save_registry(registry)

	_factory.build_index()
	var first_content := FileAccess.get_file_as_string(registry_path)

	_factory.build_index()
	var second_content := FileAccess.get_file_as_string(registry_path)

	assert_str(second_content).is_equal(first_content)


## Adding an entry between builds must rewrite the registry file.
func test_rebuild_with_new_entry_rewrites() -> void:
	_factory.save_entry("grass.tres", "grass")
	var registry := _factory.make_registry("tiles")
	var registry_path := _factory.save_registry(registry)

	_factory.build_index()
	var first_content := FileAccess.get_file_as_string(registry_path)

	_factory.save_entry("sand.tres", "sand")

	_factory.build_index()
	var second_content := FileAccess.get_file_as_string(registry_path)

	assert_str(second_content).is_not_equal(first_content)

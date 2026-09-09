extends GdUnitTestSuite

const TEST_DIR_NAME := "registry_scan"

var _factory: GdFactoryRegistry
var _registry: Registry


func before_test() -> void:
	clean_temp_dir()
	var temp_root := create_temp_dir(TEST_DIR_NAME)
	_factory = GdFactoryRegistry.new(temp_root)
	_registry = auto_free(_factory.make_registry("tiles"))


## Files that are not valid entries (wrong type or blank name) are silently
## skipped, leaving only the valid entry.
func test_skips_invalid_entries(
	file_name: String, _test_parameters := _get_invalid_entry_files()
) -> void:
	_factory.save_entry("grass.tres", "grass")
	if file_name.ends_with(".tres"):
		_factory.save_plain(file_name)
	else:
		_factory.save_entry(file_name, "")

	_registry.scan()

	assert_array(_registry.all_entry_names()).contains_exactly(["grass"])


func _get_invalid_entry_files() -> Array:
	var cases: Array[Array] = [
		["not_an_entry.tres"],
		["nameless.tres"],
	]
	for case: Array in cases:
		assert_array(case).is_not_empty()
	return cases


## Entries are stored as ResourceLink and lazily loaded via get_entry.
func test_entries_are_lazy_resource_links() -> void:
	_factory.save_entry("grass.tres", "grass")

	_registry.scan()

	assert_object(_registry.entries[&"grass"]).is_instanceof(ResourceLink)
	var loaded: Variant = _registry.get_entry(&"grass")
	assert_object(loaded).is_instanceof(TestRegistryEntry)

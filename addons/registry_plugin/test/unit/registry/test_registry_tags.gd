extends GdUnitTestSuite

const TEST_DIR_NAME := "registry_tags"

var _factory: GdFactoryRegistry
var _registry: Registry


func before_test() -> void:
	clean_temp_dir()
	var temp_root := create_temp_dir(TEST_DIR_NAME)
	_factory = GdFactoryRegistry.new(temp_root)
	_registry = _factory.make_registry("tiles")


## entries_in_tag returns the precomputed list for a tag.
func test_entries_in_tag_returns_list() -> void:
	_factory.save_entry("water.tres", "water")
	_factory.save_entry("deep_water.tres", "deep_water")
	_factory.save_entry("river.tres", "river")
	_factory.save_tag("WATER", ["water", "deep_water", "river"])

	_registry.scan()

	var entries := Array(_registry.entries_in_tag(&"WATER"))
	assert_array(entries).contains_exactly(["water", "deep_water", "river"])


func test_has_tag_membership(
	entry_name: String,
	tag_name: String,
	expected: bool,
	_test_parameters := [
		["water", "WATER", true],
		["grass", "WATER", false],
	],
) -> void:
	_factory.save_entry("water.tres", "water")
	_factory.save_entry("grass.tres", "grass")
	_factory.save_tag("WATER", ["water"])

	_registry.scan()

	assert_bool(_registry.has_tag(entry_name, tag_name)).is_equal(expected)

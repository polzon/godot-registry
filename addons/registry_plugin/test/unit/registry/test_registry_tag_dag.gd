extends GdUnitTestSuite

const TEST_DIR_NAME := "registry_tag_dag"

var _factory: GdFactoryRegistry
var _registry: Registry


func before_test() -> void:
	clean_temp_dir()
	var temp_root := create_temp_dir(TEST_DIR_NAME)

	_factory = GdFactoryRegistry.new(temp_root)
	_registry = _factory.make_registry("tiles")


## A `#`-reference is flattened so entries_in_tag returns the transitive set.
func test_flattens_cross_tag_references() -> void:
	for ore: String in ["coal_ore", "iron_ore", "gold_ore"]:
		_factory.save_entry("%s.tres" % ore, ore)
	for ore: String in ["diamond_ore", "emerald_ore"]:
		_factory.save_entry("%s.tres" % ore, ore)
	_factory.save_tag("ores", ["coal_ore", "iron_ore", "gold_ore"])
	_factory.save_tag("valuable_ores", ["#ores", "diamond_ore", "emerald_ore"])

	_registry.scan()

	var expected := [
		"coal_ore", "iron_ore", "gold_ore", "diamond_ore", "emerald_ore"
	]
	var entries := Array(_registry.entries_in_tag(&"valuable_ores"))
	assert_array(entries).contains_exactly(expected)

extends GdUnitTestSuite

const TEST_DIR_NAME := "registry_tag_provider"
const REGISTRY_NAME := &"tiles"

var _factory: GdFactoryRegistry
var _temp_root: String


func before_test() -> void:
	clean_temp_dir()

	_temp_root = create_temp_dir(TEST_DIR_NAME)
	var entries_dir := _temp_root.path_join("entries")
	DirAccess.make_dir_recursive_absolute(entries_dir)

	_factory = GdFactoryRegistry.new(_temp_root, entries_dir)
	var registry := _factory.make_registry(REGISTRY_NAME)
	_factory.save_registry(registry, "tiles_registry.tres")


## get_tag_list returns every registered tag name for the registry, sorted.
func test_get_tag_list_returns_tag_names() -> void:
	_factory.save_entry("water.tres", "water")
	_factory.save_tag("WATER", ["water"])
	_factory.save_tag("GRASS", [])

	var tags := RegistryTagProvider.get_tag_list(REGISTRY_NAME, _temp_root)

	assert_array(Array(tags)).contains_exactly(["GRASS", "WATER"])


## get_tag_list returns an empty list for an unknown registry.
func test_get_tag_list_unknown_registry_is_empty() -> void:
	var tags := RegistryTagProvider.get_tag_list(&"unknown", _temp_root)

	assert_array(Array(tags)).is_empty()


## hint_string comma-joins the tag names for PROPERTY_HINT_ENUM.
func test_hint_string_joins_tag_names() -> void:
	_factory.save_tag("WATER", [])
	_factory.save_tag("GRASS", [])

	var hint := RegistryTagProvider.hint_string(REGISTRY_NAME, _temp_root)

	assert_str(hint).is_equal("GRASS,WATER")


## variant_to_tag resolves a StringName tag name to its RegistryTag.
func test_variant_to_tag_resolves_string_name() -> void:
	_factory.save_entry("water.tres", "water")
	_factory.save_tag("WATER", ["water"])

	var tag := RegistryTagProvider.variant_to_tag(&"WATER", _temp_root)

	assert_object(tag).is_not_null()
	assert_str(tag.tag_name).is_equal("WATER")


## variant_to_tag resolves a String tag name to its RegistryTag.
func test_variant_to_tag_resolves_string() -> void:
	_factory.save_entry("water.tres", "water")
	_factory.save_tag("WATER", ["water"])

	var tag := RegistryTagProvider.variant_to_tag("WATER", _temp_root)

	assert_object(tag).is_not_null()
	assert_str(tag.tag_name).is_equal("WATER")


## variant_to_tag passes through an existing RegistryTag unchanged.
func test_variant_to_tag_passthrough_registry_tag() -> void:
	var tag := RegistryTag.new()
	tag.tag_name = "WATER"

	var result := RegistryTagProvider.variant_to_tag(tag, _temp_root)

	assert_object(result).is_same(tag)


## variant_to_tag returns null for null, empty, and unknown values.
func test_variant_to_tag_returns_null_for_invalid(
	value: Variant, _test_parameters := _get_invalid_variants()
) -> void:
	var result := RegistryTagProvider.variant_to_tag(value, _temp_root)

	assert_object(result).is_null()


## Builds the invalid-value cases; StringName literals must live in a method
## body, not an inline parameter set, or gdUnit4's expression parser rejects
## them and falls back to a slower resolver.
func _get_invalid_variants() -> Array[Array]:
	return [
		[null],
		[&""],
		[""],
		[&"UNKNOWN"],
		[42],
	]

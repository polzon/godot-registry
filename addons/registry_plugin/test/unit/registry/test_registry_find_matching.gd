extends GdUnitTestSuite

const TEST_DIR_NAME := "registry_find_matching"

const ENTRY_COUNT := 1000
const PERF_BUDGET_MS := 3000.0

var _factory: GdFactoryRegistry
var _registry: Registry


func before_test() -> void:
	clean_temp_dir()
	var temp_root := create_temp_dir(TEST_DIR_NAME)
	_factory = GdFactoryRegistry.new(temp_root)
	_registry = auto_free(_factory.make_registry("items"))


## Returns only entries matching the predicate, and an empty array when none
## match.
func test_find_matching_filters_by_predicate(
	category: String,
	expected_count: int,
	_test_parameters := _get_predicate_cases(),
) -> void:
	_registry.suppress_errors = true

	_factory.save_entry("sword.tres", "sword", "weapon")
	_factory.save_entry("shield.tres", "shield", "armor")
	_factory.save_entry("bow.tres", "bow", "weapon")

	_registry.scan()

	var matches := _registry.find_matching(
		func(entry: TestRegistryEntry) -> bool:
			return entry.category == category
	)
	assert_array(matches).has_size(expected_count)
	for match: Resource in matches:
		assert_object(match).is_instanceof(TestRegistryEntry)

	_registry.suppress_errors = false


## find_matching over 1,000 entries completes within the perf budget.
func test_find_matching_is_fast() -> void:
	for index: int in range(ENTRY_COUNT):
		_factory.save_entry("entry_%d.tres" % index, "entry_%d" % index, "item")

	_registry.scan()

	var start := Time.get_ticks_usec()
	var matches := _registry.find_matching(
		func(entry: TestRegistryEntry) -> bool: return entry.category == "item"
	)
	var elapsed_ms := (Time.get_ticks_usec() - start) / 1000.0

	assert_array(matches).has_size(ENTRY_COUNT)
	assert_float(elapsed_ms).is_less(PERF_BUDGET_MS)


func _get_predicate_cases() -> Array:
	var cases: Array[Array] = [
		["weapon", 2],
		["tool", 0],
	]
	for case: Array in cases:
		assert_array(case).is_not_empty()
	return cases

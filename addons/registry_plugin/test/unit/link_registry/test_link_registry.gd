extends GdUnitTestSuite

var _registry: LinkRegistry


func before_test() -> void:
	_registry = auto_free(LinkRegistry.new())
	_registry.set_read_only(false)


func test_link_registry_init() -> void:
	assert_object(_registry).is_not_null()


func test_db_add_get_delete_link(
	name_fuzzer := Fuzzers.rand_str(2, 12), _fuzzer_iterations := 20
) -> void:
	var link: ResourceLink = auto_free(ResourceLink.new())
	var fuzzed_name := name_fuzzer.next_value()

	# Test add and get link functionality.
	var was_successful := _registry.add_link(fuzzed_name, link)
	assert_bool(was_successful).is_true()
	assert_object(_registry.get_link(fuzzed_name)).is_equal(link)

	# Should return null after we delete it.
	_registry.delete_link(fuzzed_name)
	assert_object(_registry.get_link(fuzzed_name)).is_null()
	assert_object(link).is_not_null()


## Should successfully add a link object even if it's null.
func test_db_add_null_link(
	name_fuzzer := Fuzzers.rand_str(2, 12), _fuzzer_iterations := 5
) -> void:
	var fuzzed_name := name_fuzzer.next_value()

	var was_successful := _registry.add_link(fuzzed_name, null)
	assert_bool(was_successful).is_true()
	assert_object(_registry.get_link(fuzzed_name)).is_null()


func test_db_add_set_link_with_existing_name(
	name_fuzzer := Fuzzers.rand_str(2, 12), _fuzzer_iterations := 5
) -> void:
	# Test link 1.
	var link: ResourceLink = auto_free(ResourceLink.new())
	link.set_meta("yo", "whatup")
	var fuzzed_name := name_fuzzer.next_value()
	_registry.add_link(fuzzed_name, link)

	# Test link 2
	var another_link: ResourceLink = auto_free(ResourceLink.new())
	another_link.set_meta("notmuch", "whataboutyou")

	# Try to add another link with the same name, should fail and not overwrite.
	var was_successful := _registry.add_link(fuzzed_name, another_link)
	assert_bool(was_successful).is_false()
	var retrieved_add_link := _registry.get_link(fuzzed_name)
	assert_object(retrieved_add_link).is_not_null()
	assert_object(retrieved_add_link).is_equal(link)

	# Try to set another link with the same name, should overwrite.
	_registry.set_link(fuzzed_name, another_link)
	var retrieved_set_link := _registry.get_link(fuzzed_name)
	assert_object(retrieved_set_link).is_not_null()
	assert_object(retrieved_set_link).is_equal(another_link)

	# Ensure no data got mixed up.
	assert_object(link).is_not_equal(retrieved_set_link)
	assert_object(retrieved_add_link).is_not_equal(another_link)
	assert_object(retrieved_add_link).is_not_equal(retrieved_set_link)


func test_db_add_link_with_empty_name() -> void:
	var link: ResourceLink = auto_free(ResourceLink.new())

	# Try to add a link with an empty name, should succeed.
	var was_successful := _registry.add_link("", link)
	assert_bool(was_successful).is_true()
	assert_object(_registry.get_link("")).is_equal(link)

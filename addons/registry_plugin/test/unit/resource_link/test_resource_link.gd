extends GdUnitTestSuite

const TEMP_FILE_DIR := "resource_link"
const TEMP_SCENE_FILE := "test_resource_link_scene.tscn"
const TEMP_FULL_PATH := TEMP_FILE_DIR + "/" + TEMP_SCENE_FILE

const INVALID_UID_STR := ResourceLinkLoaderUID.INVALID_UID_STR
const INVALID_UID_INT := ResourceLinkLoaderID.INVALID_UID_INT
const INVALID_PATH := ResourceLinkLoaderPath.INVALID_PATH

var _test_file_path: String


func before() -> void:
	clean_temp_dir()
	ResourceLink._supress_warnings = true
	if _test_file_path.is_empty():
		_generate_temp_file()


func after() -> void:
	ResourceLink._supress_warnings = false


#region TESTS


## Test creating an ResourceLink with a known existing path.
func test_create_from_valid_path(
	link: ResourceLink, _test_parameters := _get_valid_resource_links()
) -> void:
	assert_object(link).is_not_null()
	if is_failure():
		fail("Failed to create ResourceLink from path: %s" % _test_file_path)
		return

	assert_str(link.res_path).is_equal(_test_file_path)
	assert_str(link.res_path).is_not_empty()
	assert_str(link.res_path).is_not_equal(INVALID_PATH)
	assert_file(link.res_path).exists().is_file()
	assert_bool(link.has_valid_path()).is_true()
	if is_failure():
		fail("File path is invalid: %s" % link.res_path)
		return

	assert_str(link.res_uid).is_not_empty()
	assert_str(link.res_uid).is_not_equal(INVALID_UID_STR)
	assert_bool(link.has_valid_uid()).is_true()
	var temp_file_path := ResourceUID.uid_to_path(link.res_uid)
	assert_file(temp_file_path).exists().is_file()
	if is_failure():
		fail("UID string is invalid: %s" % link.res_uid)
		return

	assert_int(link.res_id).is_not_equal(INVALID_UID_INT)
	assert_bool(link.has_valid_id()).is_true()
	if is_failure():
		fail("UID int is invalid: %d" % link.res_id)


## Test creating an ResourceLink with a non-existing path.
func test_create_from_invalid_path(
	link: ResourceLink, _test_parameters := _get_invalid_resource_links()
) -> void:
	assert_object(link).is_not_null()

	assert_str(link.res_path).is_equal(INVALID_PATH)
	assert_bool(link.has_valid_path()).is_false()

	assert_str(link.res_uid).is_equal(INVALID_UID_STR)
	assert_bool(link.has_valid_uid()).is_false()

	assert_int(link.res_id).is_equal(INVALID_UID_INT)
	assert_bool(link.has_valid_id()).is_false()


## Tests path to UID int and string.
func test_to_path(
	link: ResourceLink, _test_parameters := _get_valid_resource_links()
) -> void:
	var uid_str_to_path := ResourceLinkLoader.to_path(link.res_uid)
	assert_str(uid_str_to_path).is_equal(link.res_path)

	var uid_int_to_path := ResourceLinkLoader.to_path(link.res_id)
	assert_str(uid_int_to_path).is_equal(link.res_path)

	var path_to_path := ResourceLinkLoader.to_path(link.res_path)
	assert_str(path_to_path).is_equal(link.res_path)

	var null_to_path := ResourceLinkLoader.to_path(null)
	assert_str(null_to_path).is_equal(INVALID_PATH)


## Tests UID string to path and int.
func test_to_uid(
	link: ResourceLink, _test_parameters := _get_valid_resource_links()
) -> void:
	var uid_str_to_uid := ResourceLinkLoader.to_uid(link.res_uid)
	assert_str(uid_str_to_uid).is_equal(link.res_uid)

	var path_to_uid := ResourceLinkLoader.to_uid(link.res_path)
	assert_str(path_to_uid).is_equal(link.res_uid)

	var uid_int_to_uid := ResourceLinkLoader.to_uid(link.res_id)
	assert_str(uid_int_to_uid).is_equal(link.res_uid)

	var null_to_uid := ResourceLinkLoader.to_uid(null)
	assert_str(null_to_uid).is_equal(INVALID_UID_STR)


## Tests UID int to path and string.
func test_to_id(
	link: ResourceLink, _test_parameters := _get_valid_resource_links()
) -> void:
	var path_to_id := ResourceLinkLoader.to_id(link.res_uid)
	assert_int(path_to_id).is_equal(link.res_id)

	var uid_str_to_int := ResourceLinkLoader.to_id(link.res_path)
	assert_int(uid_str_to_int).is_equal(link.res_id)

	var uid_int_to_id := ResourceLinkLoader.to_id(link.res_id)
	assert_int(uid_int_to_id).is_equal(link.res_id)

	var empty_str_to_int := ResourceLinkLoader.to_id("")
	assert_int(empty_str_to_int).is_equal(INVALID_UID_INT)

	var null_to_id := ResourceLinkLoader.to_id(null)
	assert_int(null_to_id).is_equal(INVALID_UID_INT)


func test_load_resource(
	link: ResourceLink, _test_parameters := _get_valid_resource_links()
) -> void:
	var resource := link.load_resource()
	assert_object(resource).is_not_null()
	if is_failure():
		fail("Failed to load resource from path: %s" % link.res_path)
		return

	assert_object(resource).is_instanceof(PackedScene)
	assert_str(resource.resource_path).is_equal(link.res_path)


## Tests for [method ResourceLink.check_if_binary_export_enabled].
func test_binary_export_check() -> void:
	const SETTING_PATH := "editor/export/convert_text_resources_to_binary"
	if not ProjectSettings.has_setting(SETTING_PATH):
		fail("Incorrect project setting.")
		return

	var current_setting: bool = ProjectSettings.get_setting(SETTING_PATH)
	var is_enabled := ResourceLink.check_if_binary_export_enabled()
	assert_bool(is_enabled).is_equal(current_setting)

	var inverted_setting := not current_setting
	assert_bool(inverted_setting).is_not_equal(is_enabled)
	ProjectSettings.set_setting(SETTING_PATH, inverted_setting)
	var is_enabled_after_change := ResourceLink.check_if_binary_export_enabled()
	assert_bool(is_enabled_after_change).is_equal(inverted_setting)
	assert_bool(is_enabled_after_change).is_not_equal(is_enabled)


## A path with no persisted UID must resolve to the same UID on repeated
## calls, so scans do not churn the registry file.
func test_synthesized_uid_is_sticky() -> void:
	var first_uid := ResourceLinkLoader.to_uid(_test_file_path)
	var second_uid := ResourceLinkLoader.to_uid(_test_file_path)
	assert_str(second_uid).is_equal(first_uid)

	var first_id := ResourceLinkLoader.to_id(_test_file_path)
	var second_id := ResourceLinkLoader.to_id(_test_file_path)
	assert_int(second_id).is_equal(first_id)


## Two links built from the same path must compare as the same location.
func test_is_same_location() -> void:
	var link_a := ResourceLink.create_from(_test_file_path)
	var link_b := ResourceLink.create_from(_test_file_path)
	assert_bool(link_a.is_same_location(link_b)).is_true()
	assert_bool(link_a.is_equivalent_to(link_b)).is_true()


## Two links built from different paths must not compare as the same location.
func test_is_same_location_different_paths() -> void:
	var link_a := ResourceLink.new()
	link_a.res_path = "res://game/main.tscn"
	var link_b := ResourceLink.new()
	link_b.res_path = "res://game/main.gd"
	assert_bool(link_a.is_same_location(link_b)).is_false()


## A link must not compare equal to null.
func test_compare_against_null() -> void:
	var link := ResourceLink.create_from(_test_file_path)
	assert_bool(link.is_same_location(null)).is_false()
	assert_bool(link.deep_compare(null)).is_false()
	assert_bool(link.is_equivalent_to(null)).is_false()


#endregion TESTS

#region HELPERS


func _get_valid_resource_links() -> Array:
	if _test_file_path.is_empty():
		_test_file_path = "res://game/main.tscn"

	var valid_uid_int := ResourceLinkLoader.to_id(_test_file_path)
	var valid_uid_str := ResourceLinkLoader.to_uid(valid_uid_int)

	ResourceLink._supress_warnings = true
	var valid_arr: Array[Array] = [
		[ResourceLink.create_from(_test_file_path)],
		[ResourceLinkLoader.create_from_path(_test_file_path)],
		[ResourceLinkLoader.create_from_uid(valid_uid_str)],
		[ResourceLinkLoader.create_from_id(valid_uid_int)],
	]
	for link_arr: Array in valid_arr:
		assert_array(link_arr).is_not_empty()
		if not link_arr.is_empty() and link_arr[0] is ResourceLink:
			assert_object(link_arr[0]).is_not_null()
	return valid_arr


func _get_invalid_resource_links() -> Array:
	ResourceLink._supress_warnings = true
	var invalid_arr := [
		[ResourceLink.create_from(null)],
		[ResourceLink.create_from(12345)],
		[ResourceLinkLoader.create_from_path(INVALID_PATH)],
		[ResourceLinkLoader.create_from_path("res://non/existent/file.tscn")],
		[ResourceLinkLoader.create_from_uid(INVALID_UID_STR)],
		[ResourceLinkLoader.create_from_uid("what up")],
		[ResourceLinkLoader.create_from_id(INVALID_UID_INT)],
		[ResourceLinkLoader.create_from_id(1337)],
	]
	for link_arr: Array in invalid_arr:
		assert_array(link_arr).is_not_empty()
		if not link_arr.is_empty() and link_arr[0] is ResourceLink:
			assert_object(link_arr[0]).is_not_null()
	return invalid_arr


func _generate_temp_file() -> void:
	var temp_file_factory := GdFactoryTempResource.new(self)
	temp_file_factory.generate_temp_file(TEMP_FILE_DIR, TEMP_SCENE_FILE)
	_test_file_path = temp_file_factory.get_temp_file_path()

	assert_str(_test_file_path).is_not_empty()
	assert_str(_test_file_path).is_equal("user://tmp/" + TEMP_FULL_PATH)
	assert_file(_test_file_path).exists().is_file()

#endregion HELPERS

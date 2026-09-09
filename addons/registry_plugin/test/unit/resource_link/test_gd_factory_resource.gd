extends GdUnitTestSuite
## Tests [GdFactoryTempResource] to ensure it generates valid temp files with
## correct paths and handles edge cases properly.

const TEMP_PREFIX := "user://tmp/"
const VALID_EXTENSIONS := [".tscn", ".tres", ".res", ".scn"]


func before() -> void:
	clean_temp_dir()


func test_generation_stable_paths(
	relative_dir: String,
	file_name: String,
	_test_parameters := [
		["test_dir", "test_scene.tscn"], ["test_dir", "test_res.tres"]
	]
) -> void:
	var temp_file_factory := GdFactoryTempResource.new(self)
	var result := temp_file_factory.generate_temp_file(relative_dir, file_name)
	assert_int(result).is_equal(OK)

	var path := temp_file_factory.get_temp_file_path()
	assert_str(path).is_not_empty()
	assert_file(path).exists().is_file()

	var expected_path := TEMP_PREFIX + relative_dir + "/" + file_name
	assert_str(path).is_equal(expected_path)
	assert_file(expected_path).exists().is_file()


func test_generation_fuzzed_paths(
	file_name_fuzzer := Fuzzers.rand_str(2, 8),
	relative_dir_fuzzer := Fuzzers.rand_str(2, 8),
	_fuzzer_iterations := 10,
	_do_skip := true
) -> void:
	var temp_file_factory := GdFactoryTempResource.new(self)
	var file_name := file_name_fuzzer.next_value() + _get_valid_extension()
	var relative_dir := relative_dir_fuzzer.next_value()
	temp_file_factory.generate_temp_file(relative_dir, file_name)

	var path := temp_file_factory.get_temp_file_path()
	assert_str(path).is_not_empty()
	assert_file(path).exists().is_file()

	var expected_path := TEMP_PREFIX + relative_dir + "/" + file_name
	assert_str(path).is_equal(expected_path)
	assert_file(expected_path).exists().is_file()


func _get_valid_extension() -> String:
	return VALID_EXTENSIONS[randi() % VALID_EXTENSIONS.size()]

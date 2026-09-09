extends GdUnitTestSuite

const TEST_DIR_NAME := "registry_index"
const NESTED_DIR_NAME := "nested"
const FUZZER_ITERATIONS := 5
## Alphanumerics only so fuzzed names are always valid file names.
const FILE_NAME_CHARSET := "a-zA-Z0-9"

var _temp_root: String
var _expected_paths: Array[String] = []


func before_test() -> void:
	clean_temp_dir()
	_temp_root = create_temp_dir(TEST_DIR_NAME)
	_expected_paths = []


## The scanner returns exactly the files the public predicates classify as
## registry resources, across fuzzed file names and nested directories.
func test_collects_only_registry_paths(
	fuzzer_name := Fuzzers.rand_str(4, 12, FILE_NAME_CHARSET),
	_fuzzer_iterations := FUZZER_ITERATIONS,
) -> void:
	var base_name := fuzzer_name.next_value()

	# Each case: [resource to save, sub directory, file extension].
	var cases: Array[Array] = [
		[RegistryIndex.new(), "", ".tres"],
		[RegistryIndex.new(), "", ".res"],
		[Registry.new(), "", ".tres"],
		[Registry.new(), NESTED_DIR_NAME, ".tres"],
		[Resource.new(), "", ".tres"],
	]
	for index: int in range(cases.size()):
		var case_data: Array[Variant] = cases[index]
		var idx_resource: Resource = case_data[0]
		var idx_sub_dir: String = str(case_data[1])
		var idx_extension: String = str(case_data[2])
		_save_case(base_name, index, idx_resource, idx_sub_dir, idx_extension)

	_write_text_case(base_name, cases.size())

	var actual := RegistryIndex.search_registry_paths(_temp_root)
	assert_array(actual).contains_exactly_in_any_order(_expected_paths)


func _save_case(
	base_name: String,
	index: int,
	resource: Resource,
	sub_dir: String,
	extension: String
) -> void:
	var dir_path := _temp_root
	if not sub_dir.is_empty():
		dir_path = _temp_root.path_join(sub_dir)
	DirAccess.make_dir_recursive_absolute(dir_path)

	var file_name := "%s_%d%s" % [base_name, index, extension]
	var path := dir_path.path_join(file_name)
	var error := ResourceSaver.save(resource, path)
	assert(
		error == OK,
		"Failed to save case %d to %s: %s" % [index, path, error_string(error)]
	)

	var script_class := _script_class_of(resource)
	var is_expected := (
		RegistryIndex.is_resource_index(script_class, "")
		and RegistryIndex.is_supported_extension(path)
	)
	if is_expected:
		_expected_paths.append(path)


## Returns the global class name of [param resource]'s script, or "" when it
## has no script.
func _script_class_of(resource: Resource) -> String:
	var script: Script = resource.get_script()
	if not script:
		return ""
	return script.get_global_name()


## Writes a plain text file with an unsupported extension.
func _write_text_case(base_name: String, index: int) -> void:
	var file_name := "%s_%d.txt" % [base_name, index]
	var file := FileAccess.open(
		_temp_root.path_join(file_name), FileAccess.WRITE
	)
	file.store_string("not a resource")
	file.close()

extends GdUnitTestSuite

const TEST_DIR_NAME := "registry_file_parser"

var _temp_root: String


func before_test() -> void:
	clean_temp_dir()
	_temp_root = create_temp_dir(TEST_DIR_NAME)


## Reads the script class from a resource header without loading the file.
func test_script_class_from_header() -> void:
	var path := _save_resource(Registry.new())
	assert_str(RegistryFileParser.script_class(path)).is_equal("Registry")


## Reads the resource type from a header without loading the file.
func test_resource_type_from_header() -> void:
	var path := _save_resource(Registry.new())
	assert_str(RegistryFileParser.resource_type(path)).is_equal("Resource")


## A plain resource with no script has an empty script class.
func test_plain_resource_has_no_script_class() -> void:
	var path := _save_resource(Resource.new())
	assert_str(RegistryFileParser.script_class(path)).is_empty()


## A missing file yields empty values instead of an error.
func test_missing_file_yields_empty() -> void:
	var path := _temp_root.path_join("missing.tres")
	assert_str(RegistryFileParser.script_class(path)).is_empty()
	assert_str(RegistryFileParser.resource_type(path)).is_empty()


## A non-resource text file yields empty values instead of an error.
func test_non_resource_file_yields_empty() -> void:
	var path := _temp_root.path_join("plain.txt")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("not a resource")
	file.close()
	assert_str(RegistryFileParser.script_class(path)).is_empty()
	assert_str(RegistryFileParser.resource_type(path)).is_empty()


## Resolves a known global class name to its script.
func test_script_for_known_class() -> void:
	var script := RegistryFileParser.script_for_class("Registry")
	assert_object(script).is_not_null()


## An unknown class name resolves to null.
func test_script_for_unknown_class() -> void:
	RegistryFileParser.suppress_errors = true
	assert_object(RegistryFileParser.script_for_class("NoSuchClass")).is_null()
	RegistryFileParser.suppress_errors = false


## An empty class name resolves to null.
func test_script_for_empty_class() -> void:
	assert_object(RegistryFileParser.script_for_class("")).is_null()


func _save_resource(resource: Resource) -> String:
	var path := _temp_root.path_join("resource.tres")
	var error := ResourceSaver.save(resource, path)
	assert(error == OK, "Failed to save %s: %s" % [path, error_string(error)])
	return path

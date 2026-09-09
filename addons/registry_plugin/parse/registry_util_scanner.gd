class_name RegistryUtilScanner
## Static utility that walks the project tree and collects paths to resource
## files matching a caller-provided predicate.

const SEARCH_LIMIT: int = 100000
const SUPPORTED_FILE_EXTENSIONS: Array[String] = [".tres", ".res"]


## Work-around to correctly sort [param names] alphabetically. Keys must be
## converted to String first, otherwise the sort() algorithm will sort them as
## pointers, leading to inconsistent and incorrect orders.
static func sorted_string_names(names: Array) -> PackedStringArray:
	var sorted := PackedStringArray()
	for name: StringName in names:
		sorted.append(String(name))
	sorted.sort()
	return sorted


## Returns every file under [param root] (recursively) that has a supported
## extension and whose resource header satisfies [param predicate].
## [br]
## The predicate receives the file's script class name and resource type,
## read from the header without loading the resource or its dependencies.
static func find_resource_paths(
	root: String, predicate: Callable, excluded_dirs: Array[String] = []
) -> Array[String]:
	var results: Array[String] = []
	_collect_paths(root, predicate, excluded_dirs, results, 0)
	return results


static func _collect_paths(
	dir_path: String,
	predicate: Callable,
	excluded_dirs: Array[String],
	results: Array[String],
	search_count: int
) -> int:
	if search_count > SEARCH_LIMIT:
		push_warning(
			"Search limit exceeded: ",
			"Total searches: %d, " % search_count,
			"Search limit: %d" % SEARCH_LIMIT
		)
		return search_count

	if is_excluded(dir_path, excluded_dirs):
		return search_count

	var dir := DirAccess.open(dir_path)
	if not dir:
		var open_err := DirAccess.get_open_error()
		var err_str := error_string(open_err)
		push_error("Failed to open directory: %s (%s)" % [dir_path, err_str])
		return search_count

	var err := dir.list_dir_begin()
	if err != OK:
		var err_str := error_string(err)
		push_error("Failed to list directory: %s (%s)" % [dir_path, err_str])
		return search_count

	search_count += 1
	search_count = _process_entries(
		dir, dir_path, predicate, excluded_dirs, results, search_count
	)
	dir.list_dir_end()
	return search_count


static func _process_entries(
	dir: DirAccess,
	dir_path: String,
	predicate: Callable,
	excluded_dirs: Array[String],
	results: Array[String],
	search_count: int
) -> int:
	var entry_name := dir.get_next()
	while entry_name != "":
		if search_count > SEARCH_LIMIT:
			push_warning(
				"Search limit exceeded: ",
				"Total searches: %d, " % search_count,
				"Search limit: %d" % SEARCH_LIMIT
			)
			return search_count

		if entry_name == "." or entry_name == "..":
			entry_name = dir.get_next()
			continue

		var entry_path := dir_path.path_join(entry_name)
		if dir.current_is_dir():
			search_count += 1
			search_count = _collect_paths(
				entry_path, predicate, excluded_dirs, results, search_count
			)

		elif is_supported_extension(entry_path):
			search_count += 1
			var script_class := RegistryFileParser.script_class(entry_path)
			var resource_type := RegistryFileParser.resource_type(entry_path)
			if predicate.call(script_class, resource_type):
				results.append(entry_path)

		entry_name = dir.get_next()
	return search_count


static func is_excluded(dir_path: String, excluded_dirs: Array[String]) -> bool:
	for excluded in excluded_dirs:
		var normalized := excluded.rstrip("/")
		if (
			dir_path == normalized
			or dir_path.begins_with(normalized.path_join(""))
		):
			return true
	return false


static func is_supported_extension(entry_path: String) -> bool:
	for extension in SUPPORTED_FILE_EXTENSIONS:
		if entry_path.ends_with(extension):
			return true
	return false

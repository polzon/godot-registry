class_name RegistryFileParser
## Reads a resource file's header to identify its script class and type
## without loading the resource or its dependencies.

static var suppress_errors: bool = false


## Returns the script_class from the resource header, or "" when the file
## has no script class or cannot be read.
static func script_class(path: String) -> String:
	return _header_attr(path, "script_class")


## Returns the resource type from the header, or "" when unreadable.
static func resource_type(path: String) -> String:
	return _header_attr(path, "type")


## Returns the script registered under [param name], or null when the name
## is empty or not a known global class.
static func script_for_class(name: String) -> Script:
	if name.is_empty():
		return null

	for entry: Dictionary[StringName, Array] in (
		ProjectSettings.get_global_class_list()
	):
		if entry.get("class", "") == name:
			# ! Tried formalizing the types but it errors? But str() works?
			return load(str(entry.get("path", "")))

	if not suppress_errors:
		push_error("Failed to find script for class '%s'" % name)
	return null


static func _header_attr(path: String, attr: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return ""
	var header := file.get_line()
	var marker := '%s="' % attr
	var start := header.find(marker)
	if start == -1:
		return ""
	start += marker.length()
	var end := header.find('"', start)
	if end == -1:
		return ""
	return header.substr(start, end - start)

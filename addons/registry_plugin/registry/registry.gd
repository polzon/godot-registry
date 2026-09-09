@tool
class_name Registry
extends Resource
## Describes one content namespace (e.g. "tiles") and indexes its entry files
## as lazy [ResourceLink] references keyed by an exported name property.

const TAGS_SUBDIR := "tags"

@export var registry_name: String = ""

@export_group("Scan Settings")
## Root folder scanned for entry files.
@export var scan_path: String = ""
## Script type that entry files must match. When null, every supported file is
## treated as an entry.
@export var entry_type: GDScript = null
## Exported property on entry files that holds each entry's unique name.
@export var name_property: StringName = &""

@export_tool_button("Scan") var scan_button: Callable:
	get():
		return scan

@export_group("Data")
## Built index mapping entry names to lazy [ResourceLink] references.
@export var entries: Dictionary[StringName, ResourceLink] = {}
## Inverted index: tag name -> entry names in that tag.
@export var tags: Dictionary[StringName, PackedStringArray] = {}
## Inverted index: entry name -> tag names that contain it.
@export var entry_tags: Dictionary[StringName, PackedStringArray] = {}

var suppress_errors: bool = false


func add_entry(name: StringName, value: Variant) -> void:
	entries[name] = ResourceLink.create_from(value)


func remove_entry(name: StringName) -> void:
	entries.erase(name)


func has_entry(name: StringName) -> bool:
	return entries.has(name)


## Returns the entry object as a [Variant], or [null] if absent.
func get_entry(name: StringName) -> Variant:
	var link: ResourceLink = entries.get(name, null)
	if not link:
		return null
	return link.load_resource()


func all_entry_names() -> PackedStringArray:
	return entries.keys().duplicate()


func enum_hint_string() -> String:
	return ",".join(all_entry_names())


## Returns the precomputed entry names for a tag.
func entries_in_tag(tag_name: StringName) -> PackedStringArray:
	return tags.get(tag_name, [])


func has_tag(entry_name: StringName, tag_name: StringName) -> bool:
	var tag_names: PackedStringArray = entry_tags.get(entry_name, [])
	return tag_names.has(tag_name)


## Returns true if this registry holds the same entries and tags as [param
## other], ignoring UID drift in the underlying resource links.
func is_equivalent_to(other: Registry) -> bool:
	if not other:
		return false
	if not _entries_match(other):
		return false
	if tags != other.tags:
		return false
	return entry_tags == other.entry_tags


func _entries_match(other: Registry) -> bool:
	if entries.size() != other.entries.size():
		return false
	for name: StringName in entries:
		if not other.entries.has(name):
			return false
		var link: ResourceLink = entries[name]
		var other_link: ResourceLink = other.entries[name]
		if not link.is_equivalent_to(other_link):
			return false
	return true


## Lazily loads every entry and returns those matching [param predicate].
func find_matching(predicate: Callable) -> Array[Resource]:
	var matches: Array[Resource] = []
	for name: StringName in entries.keys():
		var entry: Variant = get_entry(name)
		if entry and predicate.call(entry):
			matches.append(entry)
		elif not suppress_errors:
			push_error(
				(
					"Registry '%s': failed to load entry '%s'"
					% [registry_name, name]
				)
			)
	return matches


## Walks [member scan_path], keeps files matching [member entry_type], and
## stores each as a [ResourceLink] keyed by its exported [member name_property].
func scan() -> void:
	entries.clear()
	tags.clear()
	entry_tags.clear()

	if not DirAccess.dir_exists_absolute(scan_path):
		if not scan_path.is_empty():
			if not suppress_errors:
				push_warning(
					"Registry '%s': " % registry_name,
					"scan_path does not exist: %s" % scan_path
				)
		return

	var entry_paths := RegistryUtilScanner.find_resource_paths(
		scan_path, _matches_entry_type
	)
	for path in entry_paths:
		var resource := ResourceLoader.load(path)
		var raw_name: Variant = resource.get(name_property)
		var str_name: StringName = str(raw_name)
		if raw_name == null or str_name.is_empty():
			continue
		if entries.has(str_name):
			if not suppress_errors:
				push_warning(
					"Registry '%s': " % registry_name,
					"duplicate entry name '%s' (last-write-wins)" % str_name
				)
		entries[str_name] = ResourceLink.create_from(path)

	_build_tags()


## Reads and indexes tag files from the registry's [member TAGS_SUBDIR].
func _build_tags() -> void:
	var tags_dir := scan_path.path_join(TAGS_SUBDIR)
	if not DirAccess.dir_exists_absolute(tags_dir):
		return

	var raw_tags: Dictionary[StringName, PackedStringArray] = {}
	var tag_paths := RegistryUtilScanner.find_resource_paths(
		tags_dir,
		func(script_class: String, _resource_type: String) -> bool:
			return script_class == "RegistryTag"
	)
	for path in tag_paths:
		var tag := ResourceLoader.load(path) as RegistryTag
		if not tag:
			continue
		raw_tags[tag.tag_name] = tag.entry_names

	var visited: Array[StringName] = []
	for tag_name: StringName in raw_tags:
		if visited.has(tag_name):
			continue
		var resolved := _resolve_tag(tag_name, raw_tags, [], visited)
		tags[tag_name] = resolved
		for entry_name: StringName in resolved:
			var key := entry_name
			var current: PackedStringArray = entry_tags.get(key, [])
			current.append(tag_name)
			entry_tags[key] = current


## Recursively resolves a tag's entry list, expanding `#`-references.
## [br]
## Returns an empty list and reports an error when a cycle is detected.
## [param visited] accumulates every tag touched so each cycle is reported
## only once.
func _resolve_tag(
	tag_name: StringName,
	raw_tags: Dictionary[StringName, PackedStringArray],
	stack: Array[StringName],
	visited: Array[StringName]
) -> PackedStringArray:
	if stack.has(tag_name):
		var cycle := stack.duplicate()
		cycle.append(tag_name)
		if not suppress_errors:
			push_error(
				"Registry '%s': " % tag_name,
				"tag cycle detected: %s" % " -> ".join(cycle)
			)
		return []

	var resolved: PackedStringArray = []
	stack.append(tag_name)
	visited.append(tag_name)
	for entry: StringName in raw_tags.get(tag_name, []):
		if entry.begins_with("#"):
			var ref_name := entry.substr(1)
			resolved.append_array(
				_resolve_tag(ref_name, raw_tags, stack, visited)
			)
		else:
			resolved.append(entry)
	stack.pop_back()
	return resolved


func _matches_entry_type(script_class: String, _resource_type: String) -> bool:
	if entry_type == null:
		return true
	var script := RegistryFileParser.script_for_class(script_class)
	while script:
		if script == entry_type:
			return true
		script = script.get_base_script()
	return false

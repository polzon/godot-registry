@tool
class_name RegistryTagInspectorPlugin
extends EditorInspectorPlugin
## Plugin to add a custom entry-list editor for [RegistryTag] resources.


func _can_handle(object: Object) -> bool:
	return object is RegistryTag


func _parse_property(
	object: Object,
	_type: Variant.Type,
	name: String,
	_hint_type: PropertyHint,
	_hint_string: String,
	_usage: PropertyUsageFlags,
	_wide: bool,
) -> bool:
	if object is RegistryTag and name == "entry_names":
		var tag := object as RegistryTag
		add_custom_control(RegistryTagInspectorEntry.new(tag))
		return true
	return false

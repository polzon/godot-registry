@tool
class_name RegistryPlugin
extends EditorPlugin

# REFERENCE: https://minecraft.wiki/w/Block_entity_format

var _index_dirty := false

var _export_plugin: RegistryExportPlugin
var _tag_inspector_plugin: RegistryTagInspectorPlugin


func _enter_tree() -> void:
	_enable_export_plugin()
	_enable_tag_inspector_plugin()

	var fs := EditorInterface.get_resource_filesystem()
	fs.filesystem_changed.connect(_on_filesystem_changed)


func _exit_tree() -> void:
	_disable_export_plugin()
	_disable_tag_inspector_plugin()

	var fs := EditorInterface.get_resource_filesystem()
	if fs.filesystem_changed.is_connected(_on_filesystem_changed):
		fs.filesystem_changed.disconnect(_on_filesystem_changed)


func _build() -> bool:
	return _update_index_if_dirty() == OK


func _on_filesystem_changed() -> void:
	_index_dirty = true


func _update_index_if_dirty() -> Error:
	if not _index_dirty and RegistryIndexLoader.index_exists():
		return OK

	if _index_dirty:
		print("Registry index is dirty, rebuilding...")
	elif not RegistryIndexLoader.index_exists():
		print("Registry index does not exist, building...")

	var err := RegistryIndexLoader.update_index()
	if err != OK:
		push_error("Failed to update registry index.")
	_index_dirty = false
	return err


func _enable_tag_inspector_plugin() -> void:
	if not _tag_inspector_plugin:
		_tag_inspector_plugin = RegistryTagInspectorPlugin.new()
		add_inspector_plugin(_tag_inspector_plugin)


func _disable_tag_inspector_plugin() -> void:
	if _tag_inspector_plugin:
		remove_inspector_plugin(_tag_inspector_plugin)
		_tag_inspector_plugin = null


func _enable_export_plugin() -> void:
	if not _export_plugin:
		_export_plugin = RegistryExportPlugin.new()
		add_export_plugin(_export_plugin)


func _disable_export_plugin() -> void:
	if _export_plugin:
		remove_export_plugin(_export_plugin)
		_export_plugin = null

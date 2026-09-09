@tool
class_name RegistryExportPlugin
extends EditorExportPlugin
## Builds [RegistryIndex] on exported builds.


func _get_name() -> String:
	return "RegistryIndex Export"


func _export_begin(
	_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int
) -> void:
	if RegistryIndexLoader.index_exists():
		return

	var err := RegistryIndexLoader.update_index()
	if err != OK or not RegistryIndexLoader.index_exists():
		push_error("[RegistryExportPlugin]: failed to generate registry index.")


func _export_end() -> void:
	if RegistryIndexLoader.index_exists():
		return
	push_error(
		"[RegistryExportPlugin]: registry index is missing after export."
	)

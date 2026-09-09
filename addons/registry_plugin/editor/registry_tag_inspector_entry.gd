class_name RegistryTagInspectorEntry
extends VBoxContainer
## Custom inspector button that adds a dropdown menu of possible tag entries
## that can be attached to an object.

var _tag: RegistryTag
var _rows: VBoxContainer


func _init(tag: RegistryTag) -> void:
	_tag = tag


func _ready() -> void:
	_create_header()
	_rows = VBoxContainer.new()
	add_child(_rows)
	_rebuild_rows()


func _create_header() -> void:
	# Entries label.
	var label := Label.new()
	label.text = "Entries"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Add entry button.
	var add_button := Button.new()
	add_button.icon = _get_editor_icon("Add")
	add_button.text = "Add Entry"
	add_button.tooltip_text = "You'll never guess what this does."
	add_button.pressed.connect(_on_add_pressed)

	# Combine and add controls into header.
	var header := HBoxContainer.new()
	header.tooltip_text = "Add or remove entries for this tag."
	header.add_child(label)
	header.add_child(add_button)
	add_child(header)


func _on_add_pressed() -> void:
	_tag.entry_names.append("")
	_rebuild_rows()


func _on_remove_pressed(row: Control) -> void:
	var index: int = row.get_index()
	_tag.entry_names.remove_at(index)
	_rebuild_rows()


func _on_text_changed(text: String, row: Control) -> void:
	_tag.entry_names[row.get_index()] = text


func _rebuild_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()
	for entry_name in _tag.entry_names:
		_create_tag_entry(entry_name)


func _create_tag_entry(entry_name: String) -> void:
	var row := HBoxContainer.new()

	var edit := LineEdit.new()
	edit.text = entry_name
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(_on_text_changed.bind(row))
	edit.placeholder_text = "Entry name (e.g. WaterTile)"

	var remove_button := Button.new()
	remove_button.icon = _get_editor_icon("Remove")
	remove_button.tooltip_text = (
		"You can remove this entry, "
		+ "but you can't remove your life's mistakes."
	)
	remove_button.pressed.connect(_on_remove_pressed.bind(row))
	row.add_child(edit)
	row.add_child(remove_button)
	_rows.add_child(row)


func _get_editor_icon(icon_name: String) -> Texture2D:
	return EditorInterface.get_base_control().get_theme_icon(
		icon_name, "EditorIcons"
	)

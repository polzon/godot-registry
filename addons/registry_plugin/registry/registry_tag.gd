@tool
class_name RegistryTag
extends Resource
## A tag file listing entry names for one registry. Entries are plain names,
## not resource references; `#`-prefixed entries reference other tags.

@export var tag_name: String = ""
@export var entry_names: PackedStringArray = []

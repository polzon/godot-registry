class_name TestRegistryEntry
extends Resource
## Minimal entry type used by registry tests; exposes a name property that the
## scan reads to key each entry, plus a category for predicate filtering.

@export var entry_name: String = ""
@export var category: String = ""

# Agent instructions for registry_plugin/

`registry_plugin/` is the first-party content-registry system and the core
data dependency of the world map. It maps content namespaces (like
`"tiles"`) to entry files, and wraps every reference in a `ResourceLink` so
loading survives file moves and UID drift.

## Read This First

Runtime code reaches the registry two ways:

- **`RegistryIndex`** is the lookup entry point. It is a singleton whose
  prebuilt file lives at `res://registry_index.tres`. Call the static methods
  (`find`, `get_registry`, `find_by_tag`, `has_tag`, `all_tag_names`,
  `enum_hint_string`, `has_entry_with_tag`, `find_first_by_tag`) — never
  build or edit the index file by hand.
- **`ResourceLink`** is the resilient UID/path wrapper. `engine/` and `game/`
  load scenes and resources through it; add resources by UID, not by a
  `res://` path.

`res://registry_index.tres` and `res://resources/maps/tiles_registry.tres`
are generated artifacts. Rebuild them through the loader, never by editing
them directly.

## Build / runtime flow

1. In the editor, `RegistryPlugin` (the `plugin.gd` entry point) registers
   `RegistryExportPlugin` and watches the filesystem. On any change it marks
   the index dirty and rebuilds it in `_build()`.
2. `RegistryIndexLoader.update_index()` rebuilds the whole index: it finds
   every `Registry` resource under `res://`, calls `scan()` on each, and
   saves the result to `res://registry_index.tres`. It asserts a debug build
   — the index must be built in the editor, never at runtime.
3. `Registry.scan()` walks `scan_path` via `RegistryUtilScanner`, keeps files
   matching `entry_type`, keys each by its `name_property` value, and builds
   the tag indexes from `tags/` files.
4. At export, `RegistryExportPlugin._export_begin()` builds the index if it
   is missing.

## Subsystems

- **`registry/`** — the registry core: `Registry` (one namespace and its
  index), `RegistryIndex` (the singleton lookup layer and tag bridge),
  `RegistryIndexLoader` (builds/loads/deletes the prebuilt index file), and
  the scanner/parser/export-plugin helpers.
- **`resource_link/`** — resilient file references. `ResourceLink.create_from()`
  accepts a path, UID string, or UID int; `load_resource()` tries all three.
  `loaders/` holds the format-specific loaders behind a `ResourceLinkLoader`
  facade.

## Tests

The plugin ships its own gdUnit4 suite under `test/`, run from
`godot/addons/registry_plugin/test/`. It has `factories/`, `fixtures/`, and a
`unit/` tree split by class.

Helpers in this tree predate the project-wide `Gd*` prefix convention and use
a `Test` prefix (`TestRegistryEntry`). Leave existing names; match the local
convention when adding here. Use the `gdunit4-test-writer` and
`gdunit4-test-runner` skills to write and run them.

## Deprecations

- `TileDB`, `TileIndex`, and `TileTagRegistry` (in `addons/worldmap/tiles/`)
  are deprecated:
  - `TileDB` → `RegistryIndex.find(&"tiles", entry_name)`
  - `TileIndex` → a `Registry` resource with a `scan_path`
  - `TileTagRegistry` → `RegistryIndex.has_tag` / `all_tag_names` /
    `enum_hint_string` with the `&"tiles"` registry name
- `LinkRegistry` (in `registry/link_registry.gd`) is deprecated. Replace with
  `Registry.entries` (a `Dictionary[StringName, ResourceLink]`).

## Code Barriers / Gotchas

- **The index file is generated.** Do not hand-edit `res://registry_index.tres`
  or `resources/maps/tiles_registry.tres`; rebuild through
  `RegistryIndexLoader.update_index()`. Runtime loads the prebuilt file and
  warns when it is missing.
- **Build in editor, load at runtime.** `update_index()` asserts
  `OS.is_debug_build()`. The export plugin is what guarantees an index exists
  in shipped builds.
- **The scanner reads headers, not resources.** `RegistryUtilScanner` uses
  `RegistryFileParser` to identify classes without loading them, so it stays
  cheap and avoids dependency cascades. Keep the predicate a static class
  check (e.g. `script_class == "Registry"`), not a `load()`.
- **Duplicate entry names are last-write-wins.** `scan()` warns and
  overwrites.
- **Tag cycles error.** `_resolve_tag()` reports a cycle once and returns an
  empty list for it.
- **`ResourceLink` warnings are suppressible.** The static `_supress_warnings`
  flag (misspelled — keep it for API compatibility) silences the
  `push_error`/`push_warning` calls; tests set it.

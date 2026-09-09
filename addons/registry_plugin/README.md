# What is it

Registry tags help organize a global databse for the project to access resources in a more stable manner.

## Format:

```
# To get a file with the tag 'tag1' in global namespace.
namespace:tag1

# To get a file nested deeper
namespace:tiles/dirt
```

# PLANS:

## High

- [ ] Add support for tag types.
  - Example, a tag named "dirt" with the tag type of "block" would be accessed by "#namespace:block:dirt"
  - Tag types also can have expected subdir, so they can work with global directory.
    - Syntax could be something like `#blocks:block:wood/darkwood.tres`
    - Example: "block" tag type has an expected type (for type safety) and subdir.
    - So if global dir is `resources/tags`, and the tag type for block has an expected type and subdir of `blocks/`, we then can access `#block:dirt` for the file at resources/tags/blocks/dirt.tres of tag type TagBlock.
- [ ] Tags no longer become resource files, but rather directory locations. (?)

## Medium

- [ ] Add support for loading via load("#namespace:tagname")
- [ ] Add a project setting for the expected root dir of tags.
- [ ] Add context menu support to copy tag path.
- [ ] Namespace can become the root directory. (?)
  - Namespaces could be considered optional and we could define a global location.

# TBD:

Things I'm still trying to decide.

- Do we remove namespaces? If we keep them, should we change the syntax?
- I do want tag types, that is decided, but I'm unsure if the directory should determine the tag type, or if we should place a TagTypeDef file at the root of a folder where a TagType should begin.
  - If we do it via directory, we would still have to add support in the project settings or something similar so we can define expected types and subdirs.
  - If we do it via file at the root of a directory, it becomes easier to change later on, becomes basically impossible to break the indexing, and we only need to worry about type safety in that resource file. A lot less work.
    - Probably will decide on the root file via directory. Less work and more verisitility.
- We could use the meta property to add multiple applied tags to any file, but this would then use up the meta property which has a single slot and the docs mention not to rely on it. Also with the folder as a tag structure, this likely wouldn't work.

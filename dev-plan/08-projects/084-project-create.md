# 084 — Create and duplicate a project

**Phase** 08 · Projects  |  **Depends on** [044](../03-design-system/044-app-form-scaffold.md), [066](../05-file-storage/066-project-folder-service.md), [082](082-project-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One short form that creates the project row, its folder tree and its default context definition in a single
transaction, and a duplicate action that starts a new project from an existing one's structure — templates, context
definitions, reference data and settings — carrying no records.

## Files

- `frontend/lib/features/projects/presentation/project_create_screen.dart` (new)
- `frontend/lib/features/projects/presentation/project_duplicate_action.dart` (new)

## Steps

1. Fields: name, optional description, optional organisation. Everything else is defaulted, not asked (FE-SIMP-05).
2. Derive `folderName` through `project_folders.dart`, then write the row, the folder tree and the default context
   definition in one transaction. A failed folder write rolls the row back and leaves no partial tree behind.
3. Duplicate copies templates, context definitions, reference data and project settings under a new id and a new folder
   tree; it copies no records, no photos and no audio. The suggested name is editable before the copy commits.
4. Route the duplicate through the same create path, so there is one transaction boundary and one rollback route for
   both entry points.
5. Open the new project on success by setting `CurrentProject`, so creation lands the user in it.

## Constraints

- Row and folder tree succeed or fail together; a half-created project must be impossible (FE-STATE-07).
- The folder tree is only ever created through `project_folders.dart`; neither screen touches the filesystem directly
  (FE-STR-11).

## Definition of done

- [x] A project exists and is ready for capture after one screen.
- [x] A failed folder creation leaves no project row and no partial folder tree.
- [x] A duplicate has zero records and identical structure — same template, context and reference counts, new id, new
  folder.
- [x] Tests: a rollback test with a failing folder-service fake; a duplication test asserting a record count of zero and
  equal structure counts; widget tests of the form's validation and failure states.

## Out of scope

- Importing a bundle as a new project.

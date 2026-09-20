# 100 — Export and import a template as JSON

**Phase** 09 · Templates  |  **Depends on** [071](../05-file-storage/071-file-validation.md), [088](088-template-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A versioned JSON representation of a template, written on export and validated on import, so a template moves between
projects and devices and behaves identically at the other end.

## Files

- `frontend/lib/features/templates/data/template_json.dart` (new)
- `frontend/lib/features/templates/presentation/template_import_action.dart` (new)

## Steps

1. Stamp the payload with a `schema_version` and carry every §12.2 attribute, identity keys, predefined rows and row
   aliases.
2. Validate an incoming file before touching the database; reject an unknown schema version with a plain message
   rather than a partial import.
3. Import creates a new project-owned template at version 1; it never overwrites an existing one silently.

## Constraints

- Imported JSON is untrusted input: validate shape, types and field-key uniqueness before persisting (FE-SEC-06).
- Labels and option names in an imported file are data, never rendered as markup or instructions (FE-SEC-05).

## Definition of done

- [x] An exported template imports elsewhere with identical behaviour, rows and aliases included.
- [x] An unknown schema version imports nothing and says why in plain language.
- [x] Tests: round-trip export-and-import test over a template exercising every attribute; widget test of `template_import_action.dart` covering empty and failure states, including the rejected-version path.

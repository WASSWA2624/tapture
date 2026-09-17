# 214 — Merge photos, templates and reference data

**Phase** 19 · Bundles and merge  |  **Depends on** [055](../04-data-layer/055-photos-table.md), [056](../04-data-layer/056-reference-tables.md), [099](../09-templates/099-template-versioning.md), [213](213-merge-entity-level.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The three entity types whose merge is not a field comparison: photos union by content hash, templates resolve by
version, and reference rows merge by key. Each contributes decisions and conflicts to the plan of 397.

## Files

- `frontend/lib/features/merge/domain/merge_photos.dart` (new)
- `frontend/lib/features/merge/domain/merge_templates.dart` (new)
- `frontend/lib/features/merge/domain/merge_reference.dart` (new)

## Steps

1. Photos: match on SHA-256 so identical content is stored once; merge captions per field; keep the importing device's
   order and append incoming photos after it.
2. Templates: the same version on both sides is no action; different versions raise a conflict offering choose one or
   keep both, and records keep the version they were captured under either way.
3. Reference data: merge rows by their key; a key present on both sides with differing attributes raises a conflict
   rather than overwriting.

## Constraints

- Photo bytes are never rewritten during a merge; deduplication changes rows, not files (FE-SEC-08).
- Keeping both templates must not rewrite any record's `templateVersion` (FE-STATE-06).

## Definition of done

- [ ] The same photo imported twice occupies one file, with both sides' captions preserved.
- [ ] Records keep the template version they were captured under, whichever template resolution is chosen.
- [ ] A reference key whose attributes differ appears as a conflict, never as a silent overwrite.
- [ ] Tests: unit tests of `merge_photos.dart` asserting a single stored file and merged captions, `merge_templates.dart` over same version, choose one and keep both, and `merge_reference.dart` over new, identical and differing rows, with no Flutter binding.

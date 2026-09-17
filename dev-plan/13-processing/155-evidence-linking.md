# 155 — Evidence links and provenance

**Phase** 13 · Processing  |  **Depends on** [051](../04-data-layer/051-tombstones-table.md), [057](../04-data-layer/057-jobs-table.md), [144](144-image-preprocessing.md), [151](151-proposal-application.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Every applied value tied to the photo region, page or transcript that produced it, and stamped with how it was
produced, so an auditor can tell how any value came to exist without a server.

## Files

- `frontend/lib/features/processing/domain/evidence_linking.dart` (new)
- `frontend/lib/features/processing/domain/provenance.dart` (new)

## Steps

1. Write at least one evidence row (task 057) per applied value: photo id with the bounding region when the provider
   supplies one, the OCR block when the value came from local extraction, the whole photo otherwise.
2. Stamp source, method, provider, model and prompt version on the value.
3. Write the application to the audit table (task 051) with the same stamp.

## Definition of done

- [ ] Every extracted value can be traced to a source in the review screen.
- [ ] Tests: unit tests that each applied value writes at least one evidence row and a complete provenance stamp, and
      that a value with no locatable region still links to its photo, with no Flutter binding.

# 149 — Build and batch the extraction request

**Phase** 13 · Processing  |  **Depends on** [029](../02-foundation/029-ai-service-interface.md), [088](../09-templates/088-template-model.md), [144](144-image-preprocessing.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One request per record, composed from the template field list, context, OCR text, captions and compressed images,
capped at a fixed number of images and split deterministically when a record carries more.

## Files

- `frontend/lib/features/processing/domain/extraction_request.dart` (new)
- `frontend/lib/features/processing/domain/request_batching.dart` (new)

## Steps

1. Carry the explicit rules in the request: only evidence-supported values, null when unknown, valid JSON.
2. Attach compressed copies, never originals.
3. Group every photo of a record into one request; read the per-request image cap from `AppConstants` and split
   larger sets by capture order, so the same record always splits the same way.

## Constraints

- OCR text, captions, field names and file names are quoted as data, never interpolated into the instruction
  (FE-SEC-05).

## Definition of done

- [ ] A five-photo record produces exactly one extraction call.
- [ ] The request matches the specification example in shape.
- [ ] Tests: golden test of a serialised request; unit tests of batching below, at and above the cap, with no Flutter
      binding.

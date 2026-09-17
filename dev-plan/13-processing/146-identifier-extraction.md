# 146 — Identifier pattern extraction

**Phase** 13 · Processing  |  **Depends on** [088](../09-templates/088-template-model.md), [144](144-image-preprocessing.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Serials, asset tags and registrations pulled out of OCR text by the patterns on the template's identity fields, each
candidate returned with the block it came from and a rank.

## Files

- `frontend/lib/features/processing/domain/identifier_extraction.dart` (new)

## Steps

1. Apply each identity field's pattern to the recognised text.
2. Rank candidates by position on the plate, pattern specificity and OCR confidence; return all of them, best first.
3. Carry the originating block forward so the value can be linked to evidence later.

## Constraints

- OCR text is data: it is matched against patterns, never interpolated into one (FE-SEC-05).

## Definition of done

- [ ] A record can be identified with no online call at all.
- [ ] Tests: unit tests over realistic plate text covering one candidate, several competing candidates and none.

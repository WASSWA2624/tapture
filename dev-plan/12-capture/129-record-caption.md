# 129 — Record and per-photo captions

**Phase** 12 · Capture  |  **Depends on** [035](../03-design-system/035-app-text-field.md), [055](../04-data-layer/055-photos-table.md), [121](121-capture-screen.md), [127](127-photo-viewer.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The record's main description, typed or spoken and stored raw as it is entered, and a per-photo caption editable
independently from either the thumbnail or the viewer.

## Files

- `frontend/lib/features/capture/presentation/record_caption_field.dart` (new)
- `frontend/lib/features/capture/presentation/photo_caption_sheet.dart` (new)

## Steps

1. Persist the record caption as the raw caption as it changes, so backgrounding needs no explicit save.
2. Open the photo sheet from the thumbnail or the viewer with the existing caption loaded for editing.
3. Write each photo caption as its own row keyed to that photo (101).

## Constraints

- Raw captions are append-only: an edit writes a new raw value with an audit entry rather than overwriting (FE-SEC-08, FE-SEC-09).
- Caption text is user data and is never interpolated into a provider instruction (FE-SEC-05).
- A write failure keeps the text on screen and offers retry; nothing typed is discarded (FE-SIMP-09).

## Definition of done

- [ ] Caption text survives backgrounding with no explicit save.
- [ ] A photo caption can be edited without touching the record caption or any other photo's caption.
- [ ] Tests: widget tests of `record_caption_field.dart` (typing, backgrounding, write failure) and `photo_caption_sheet.dart` (empty, existing caption, write failure).

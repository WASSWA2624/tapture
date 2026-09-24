# 064 — Resolve projects and capture feedback

**Phase** 23 · Hardening  |  **Depends on** [012](../12-capture/012-capture.md), [063](063-resolve-feedback-23092026-2222.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Close feedback archive 24092026-1016: visible captured photos and records, photo captions from the tray, one add-photo sheet, search and filters that match the reports, aligned project home, a searchable shipped library, a clear pinned-fields empty state, and a visible project export.

The executable prompt is `prompts/feedback-24092026-1016/001-resolve-projects-capture-feedback.md`.

## Files

- `frontend/lib/core/widgets/`
- `frontend/lib/features/capture/`
- `frontend/lib/features/projects/`
- `frontend/lib/features/templates/`
- `frontend/lib/features/context/`
- `frontend/lib/app/`
- `frontend/test/`

## Definition of done

- [x] Captured photos show in the tray and the viewer when the file or the session bytes exist.
- [x] Captured records appear in the Ready to process count and on the project records list.
- [x] Photo captions can target the latest photo, the selection, and every photo from the capture page.
- [x] Add photo is one sheet with icon buttons, and the tray add control matches the thumbnail.
- [x] Project search holds the filter after the microphone, and filters are a Projects › Filters page.
- [x] Project rows drop Last worked, mark archived projects, and sit close under the header.
- [x] Project home rows and destination cards align, and the cards read as buttons.
- [x] The shipped library can be searched and filtered by kind.
- [x] Pinned fields tell the operator to mark a field when a template is already attached.
- [x] Export is in both project menus and writes a new `.xlsx` without replacing an earlier one.
- [x] Tests: repositories, routes, widgets, and failure paths named by the prompt.

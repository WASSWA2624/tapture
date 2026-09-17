# 188 — Attendance sheet: capture, read and match

**Phase** 17 · Meetings  |  **Depends on** [111](../10-reference-data/111-lookup-exact-match.md), [123](../12-capture/123-camera-shutter.md), [126](../12-capture/126-photo-tray.md), [144](../13-processing/144-image-preprocessing.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Photograph the signed attendance sheet as ATTENDANCE evidence, read it into editable attendee rows, and offer — never
impose — a link from each name to the Staff reference dataset.

## Files

- `frontend/lib/features/meetings/presentation/attendance_capture.dart` (new)
- `frontend/lib/features/meetings/domain/attendance_ocr.dart` (new)
- `frontend/lib/features/meetings/domain/attendee_matching.dart` (new)

## Steps

1. Capture through the shutter of 221 with the photo typed ATTENDANCE by 234. The sheet remains evidence whatever the
   reading later produces.
2. Detect the name, title, organisation and signature-present columns, emitting one row per line with a confidence per
   cell (266).
3. Match names against the Staff dataset with the fuzzy matcher of 197 and attach the score. Below the threshold no
   suggestion is offered and nothing is linked.

## Definition of done

- [ ] Every extracted row is editable before it joins the attendee list, and none is added silently.
- [ ] No attendee is linked to a staff row without a person accepting the suggestion.
- [ ] A sheet that reads badly still leaves its photo attached and the attendee list editable by hand.
- [ ] Tests: widget test of `attendance_capture.dart` including its empty and failure states; test of
      `attendance_ocr.dart` against a fixture attendance sheet asserting the columns and the per-row confidence; unit
      tests of `attendee_matching.dart` over above- and below-threshold scores, with no Flutter binding.

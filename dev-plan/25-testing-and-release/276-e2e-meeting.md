# 276 — End-to-end: meeting

**Phase** 25 · Testing and release  |  **Depends on** [190](../17-meetings/190-minutes-refinement.md), [272](272-e2e-capture-to-export.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One integration run over the meeting record type, which no other journey touches: create a meeting, build attendance
from a photographed sign-in sheet, refine the minutes, export the PDF.

## Files

- `frontend/integration_test/meeting_test.dart` (new)

## Steps

1. Create a meeting with a date, location and inherited project context.
2. Add attendance by photographing a sign-in sheet; assert the extracted names arrive as a proposal, that nothing is
   recorded until a person approves, and that a corrected name replaces only its own entry.
3. Refine the minutes; assert the raw transcript and the refined text both exist and that the raw copy is unchanged.
4. Export the minutes PDF; assert it names the meeting, the approved attendance list and the decisions, and that the
   export runs with the network off.

## Constraints

- Refinement writes beside the original; the raw transcript column is read after refinement and asserted identical
  (FE-SEC-08).
- Extracted attendance is a proposal a person approves, never an accepted write (FE-TEST-10 covers the rejection path
  too: a discarded proposal leaves no attendance row).

## Definition of done

- [ ] Attendance derived from a photo is editable and reaches the record only through approval.
- [ ] The exported PDF matches the approved minutes and attendance, and is produced offline.
- [ ] Tests: `meeting_test.dart` runs green offline against fakes, end to end, including the discarded-proposal path.

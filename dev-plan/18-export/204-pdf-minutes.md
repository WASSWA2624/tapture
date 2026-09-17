# 204 — Meeting minutes PDF

**Phase** 18 · Export  |  **Depends on** [190](../17-meetings/190-minutes-refinement.md), [201](201-pdf-engine.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Formatted minutes for one meeting: attendance list, agenda items with their decisions and actions, and a photo
appendix. Raw and refined minutes can both be included, each clearly labelled as which it is.

## Files

- `frontend/lib/core/export/pdf/minutes_report.dart` (new)

## Steps

1. Take the refined text from 354 and the raw transcript beside it; never present refined text as if it were recorded
   speech.
2. Put photos in an appendix through the engine's photo block, referenced from the item that mentions them.

## Constraints

- Refinement is attributed wherever it appears: a refined passage carries its label in the document itself
  (FE-SEC-08, FE-SEC-09).

## Definition of done

- [ ] Attendance, agenda items, decisions, actions and the photo appendix all appear for a seeded meeting.
- [ ] Both raw and refined minutes can be included, and a reader can always tell which is which.
- [ ] Tests: golden test of a rendered minutes page, plus a unit test asserting raw and refined passages are labelled distinctly.

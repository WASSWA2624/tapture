# 181 — Review row controls: raw, refined, confidence and gaps

**Phase** 16 · Review  |  **Depends on** [039](../03-design-system/039-app-status-pill.md), [151](../13-processing/151-proposal-application.md), [156](../13-processing/156-caption-refinement.md), [157](../13-processing/157-no-invention-guard.md), [180](180-review-screen.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The three controls a review row is built from: the toggle that decides whether the raw or the refined value is
authoritative, the confidence indicator, and the row that turns a not-detected value into a next step instead of a
blank.

## Files

- `frontend/lib/features/review/presentation/raw_refined_toggle.dart` (new)
- `frontend/lib/features/review/presentation/confidence_indicator.dart` (new)
- `frontend/lib/features/review/presentation/not_detected_row.dart` (new)

## Steps

1. The toggle works per field and per caption, sets `valueFinal` to the chosen side, and leaves both sides stored. The
   most recent choice becomes the project's default for later fields.
2. The indicator renders the band from 286 as colour, icon and the number together, on the shared status pill of 067.
3. The not-detected row offers "type it" and "photograph the label" in place, so a value the guard of 290 refused to
   invent still has an obvious next action.

## Constraints

- A band is never signalled by colour alone (FE-A11Y-05, FE-THEME-05).
- These are one row, one pill and one tile from the catalogue, not three new visual idioms (FE-CONS-06).
- Every control is at least 48dp and carries a label (FE-A11Y-01, FE-A11Y-02).

## Definition of done

- [ ] Choosing raw or refined changes only which value is final; neither version is destroyed and the choice reverses.
- [ ] A later field in the same project starts on the remembered side.
- [ ] A not-detected field offers typing and photographing in place, and never displays an invented value.
- [ ] Tests: widget tests of `raw_refined_toggle.dart` over both selections and the remembered default,
      `confidence_indicator.dart` over all three bands asserting icon and number are both present, and
      `not_detected_row.dart` over both affordances — each including its empty and failure states.

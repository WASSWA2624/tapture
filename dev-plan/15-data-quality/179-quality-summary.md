# 179 — Project quality summary

**Phase** 15 · Data quality  |  **Depends on** [170](170-validation-engine.md), [174](174-duplicates-screen.md), [178](178-variance-screen.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One screen answering what still blocks a clean export: how many records are invalid, how many duplicate pairs and
source conflicts are unresolved, and how many records are unreviewed.

## Files

- `frontend/lib/features/quality/presentation/quality_summary_screen.dart` (new)

## Steps

1. Take the counts from the engine of 315, the duplicates table and the variance data; do not recount with query logic
   of its own.
2. Each count opens the screen that clears it — the duplicates screen, the variance screen, the batch review queue, or
   a filtered record list.

## Definition of done

- [ ] Clearing every count on this screen leaves the project export-ready, with no further check hidden elsewhere.
- [ ] Each count is tappable and lands on the screen that resolves it.
- [ ] Tests: widget test of `quality_summary_screen.dart` covering a clean project, each non-zero count and where it
      navigates, and its failure state.

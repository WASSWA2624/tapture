# 323 — Redesign the project home count cards

**Phase** 08 · Projects  |  **Depends on** [085](085-project-home.md), [314](314-add-project-management-actions.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The project home's Review, Process, Export and Share cards each show their name once and their
count as a large number. They sit in a 2×2 grid on compact widths and in one row on medium and
expanded.

## Files

- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/test/features/projects/presentation/project_home_screen_test.dart`

## Constraints

- Keep `AppCard`, and add no new card widget (FE-CONS-01).
- Numbers are formatted for the active locale, the same way the catalogue fields do it
  (FE-CONS-09, FE-L10N-04).
- Choose the layout by size class, never by measuring width; test three widths and two
  orientations (FE-RESP-02, FE-RESP-10).
- Each card reads as one sentence, and nothing clips at 200 percent (FE-A11Y-02, FE-A11Y-03).
- No sentence is assembled from parts; the semantic label is the existing plural message
  (FE-L10N-03).
- Tokens only. Continue capturing stays the only primary action (FE-THEME-01, FE-SIMP-01).
- Do not change where each card navigates or its filter, the counts provider, the Continue
  capturing action, or the header.

## Definition of done

- [x] No card repeats its name; each shows, for example, "Review" and "0".
- [x] Phone portrait shows two rows of two cards, and tablet and desktop show one row of four.
- [x] No text wraps inside a card at 360 dp, and nothing clips at 200 percent text or in
      landscape.
- [x] A screen reader hears "0 to review" and similar for each card.
- [x] Tests: each card shows its name once and its number; semantics read the pending
      sentence; 393 dp is 2×2 and 800 / 1200 dp are one row; landscape and 200 percent text
      show no overflow; navigation still reaches each list with its filter.

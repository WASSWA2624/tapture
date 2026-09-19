# 010 — Redesign the project home count cards

**Feedback:** FBK0000014 · **Type:** Improvement · **Priority:** P5 · **Effort:** M · **Depends on:** 001

## Goal
The project home's Review, Process, Export and Share cards each show their name once and their count as a
large number, with no repeated words and no wrapping inside a card. They sit in a 2×2 grid on compact
widths and in one row on medium and expanded, in light, dark and outdoor, and stay readable at 200
percent text.

## Evidence
- FBK0000014 (first part): the reporter asks for better-looking Review, Process, Export and Share buttons
  and points out that their contents repeat. `screenshots/FBK0000014.png` shows four narrow cards reading
  "Review / 0 to review", "Process / 0 to process" and so on, with each count wrapped onto two lines.
  Android, mobile, compact (393 dp), portrait, system dark, route `/projects/<id>`.
- Root cause:
  - `_CountCard` renders `label` (`Copy.homeReview`, "Review") above `countLabel`
    (`Copy.homeReviewPending(n)`, "0 to review"), so the noun appears twice
    (`frontend/lib/features/projects/presentation/project_home_screen.dart:180-215`;
    `frontend/lib/core/copy/copy.dart:522`, `:541-547`).
  - The four cards share one `Row` of `Expanded` children at every width (`project_home_screen.dart:134-176`),
    leaving about 80 dp each on a phone.

## Scope
- Change:
  - `project_home_screen.dart`, `_CountCard`: show the label as a caption and the count as a number in a
    larger token style (`AppText.title`), formatted with `NumberFormat.decimalPattern` for the active locale, as `app_text_field.dart:339` does. Set the card's
    semantic label to the full `Copy.home…Pending(n)` sentence.
  - `project_home_screen.dart`, `_HomeBody`: a 2×2 grid when `context.sizeClass` is compact, and one row
    of four otherwise, with `Space.x2` gaps.
  - `frontend/test/features/projects/presentation/project_home_screen_test.dart`: the tests below.
- Do not change: where each card navigates or its filter (task 085), the counts provider, the Continue
  capturing action, or the header added in 001.

## Rules
- FE-CONS-01: keep `AppCard`, and add no new card widget.
- FE-CONS-09 and FE-L10N-04: numbers are formatted for the active locale, the same way the catalogue fields do it.
- FE-RESP-02 and FE-RESP-10: choose the layout by size class, never by measuring width; test three
  widths and two orientations.
- FE-A11Y-02 and FE-A11Y-03: each card reads as one sentence, and nothing clips at 200 percent.
- FE-L10N-03: no sentence is assembled from parts; the semantic label is the existing plural message.
- FE-THEME-01: tokens only. FE-SIMP-01: Continue capturing stays the only primary action.

## Steps
1. Record the work in the plan with
   `cd frontend && dart run tool/new_task.dart 08-projects redesign-project-home-count-cards "Redesign the project home count cards"`
   (FE-FLOW-08).
2. Restyle `_CountCard`, then lay out the four cards by size class.
3. Tests:
   - each card shows its name once and its number;
   - each card's semantics read "N to review", "N to process", and so on;
   - at 393 dp the cards form a 2×2 grid, and at 800 and 1200 dp a single row;
   - landscape and 200 percent text show no overflow;
   - the existing navigation test still reaches each list with its filter.

## Human review
⛔ Stop before step 2 and ask:
- Layout: (a) name plus a large number, 2×2 on phones and one row wider; or (b) four full-width list rows,
  "Review · 0"? Recommend (a), because it keeps the cards task 085 specified and fixes the repetition and
  the wrapping.
Proceed only with an explicit answer. If the answer is "proceed", do (a).

## Acceptance criteria
- [ ] No card repeats its name; each shows, for example, "Review" and "0".
- [ ] Phone portrait shows two rows of two cards, and tablet and desktop show one row of four.
- [ ] No text wraps inside a card at 360 dp, and nothing clips at 200 percent text or in landscape.
- [ ] A screen reader hears "0 to review" and similar for each card.
- [ ] It looks right in light, dark and outdoor.
- [ ] FBK0000014 is resolved together with 009.

## Verification
- `cd frontend && dart run tool/verify.dart --fast` is green, then the full `dart run tool/verify.dart`.
- No goldens change.

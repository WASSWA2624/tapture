# 328 — Show the project count on the Projects destination

**Phase** 06 · Application shell  |  **Depends on** [073](073-nav-shell.md), [083](../08-projects/083-project-list.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The Projects destination shows how many active projects sit behind it — on the compact bar and on
the medium and expanded rail — so the menu says how much is there without being opened. The count
is derived from the existing list watch, announced to screen readers, and capped at `99+` on the
badge so 200 percent text cannot push the label out.

## Files

- `frontend/lib/features/projects/presentation/current_project.dart`
- `frontend/lib/features/projects/projects.dart`
- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/app/nav_destination_golden_test.dart`
- `frontend/test/features/projects/presentation/current_project_test.dart`
- `frontend/test/core/copy/copy_test.dart`

## Constraints

- Four destinations. A count is not a fifth (FE-SIMP-02). Capture, Records and Settings get no badge.
- No `MediaQuery` width comparison; the same destination badge feeds `_Bar` and `_Rail` (FE-RESP-02).
- Count active projects only, so the number matches what the destination opens onto.
- The count is derived from `projectListProvider`, never stored and never a second query
  (FE-STATE-06).
- ICU plural plus `intl` for the number (FE-L10N-03, FE-L10N-04). The badge caps at `99+`; the
  semantic label keeps the exact count.
- Token colours in all three themes, including the inverted light-desktop rail (FE-THEME-01, FE-THEME-10).
- The badge is a number, never colour alone (FE-THEME-05, FE-A11Y-05). It announces when it changes
  (FE-A11Y-07). In RTL it sits at the icon's end (AlignmentDirectional).

## Definition of done

- [x] With no projects the destination shows no badge; with projects it shows the count.
- [x] Creating, archiving, deleting and restoring updates the badge live.
- [x] The badge appears on the bar at 400 dp and on the rail at 800 and 1200 dp, both orientations.
- [x] Screen readers hear a plural-correct, locale-formatted count.
- [x] The badge meets 4.5:1 in light, dark and outdoor, including on the inverted rail.
- [x] At 200 percent text nothing clips and no label is pushed out.
- [x] In RTL the badge uses the icon's end, not hard right.
- [x] Capture, Records and Settings stay visually unchanged.

# 115 — Context bar, level picker and pinned fields

**Phase** 11 · Context  |  **Depends on** [037](../03-design-system/037-app-chip.md), [041](../03-design-system/041-app-dialog-service.md), [075](../06-app-shell/075-status-line.md), [095](../09-templates/095-field-add-basic.md), [111](../10-reference-data/111-lookup-exact-match.md), [113](113-context-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The always-visible breadcrumb of current values, the sheet that sets one level from recents, a reference dataset or
free text, and the sheet that pins any stickable non-hierarchical field — surveyor, funder, survey date — as a chip
beside the levels with the same prefill behaviour.

## Files

- `frontend/lib/features/context/presentation/context_bar.dart` (new)
- `frontend/lib/features/context/presentation/context_picker_sheet.dart` (new)
- `frontend/lib/features/context/presentation/pinned_fields_sheet.dart` (new)

## Steps

1. Render levels as `AppChip` with separators, pins after them and visibly marked as pins; tapping a chip opens the
   picker for that level or pin.
2. Truncate the longest middle value first on narrow widths; the bar never grows past two lines and is hidden entirely
   when the context is empty.
3. The picker lists recent values for that level first, then dataset search where the level is bound to one (196),
   then an explicit "use this value" for free text.
4. Offer pinning only for fields the template marks stickable (164).

## Constraints

- Chips, separators, sheets and empty states come from the design system; no bespoke chip or sheet (FE-CONS-01, FE-THEME-01).
- The bar reads the size class from `core/`; it never measures the screen itself (FE-RESP-02).
- Every chip and sheet row is a 48dp target with a semantic label (FE-A11Y-01, FE-A11Y-02).

## Definition of done

- [ ] The bar fits a 320dp-wide phone with long facility names without wrapping to a third line.
- [ ] Setting a facility takes two taps on the second visit to it.
- [ ] A survey date pinned once applies to every record afterwards without being retyped.
- [ ] Tests: golden of `context_bar.dart` at three widths with long values and at 200 percent text scale; widget tests of `context_picker_sheet.dart` and `pinned_fields_sheet.dart` covering no recents, dataset search, free-text entry and a repository failure.

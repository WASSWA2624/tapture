# 130 — Caption scope and apply mode

**Phase** 12 · Capture  |  **Depends on** [126](126-photo-tray.md), [129](129-record-caption.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The explicit target selector from the specification — this photo, selected photos, all photos — with the count always
visible, and the append-or-replace choice that writes one independent caption row per photo in scope.

## Files

- `frontend/lib/features/capture/presentation/caption_scope_selector.dart` (new)
- `frontend/lib/features/capture/domain/caption_apply.dart` (new)

## Steps

1. Default to this photo when opened from a single thumbnail, and to selected when opened from multi-select.
2. Label every option with its exact count, for example "Selected photos (3)" and "All photos (7)".
3. Append adds the new text on a new line; replace keeps the previous text recoverable from history.

## Constraints

- The count is rendered as text, never implied by a highlight alone (FE-A11Y-05).
- Replace never destroys the previous raw caption; the earlier value stays readable in history (FE-SEC-08).

## Definition of done

- [ ] A caption can never be applied without the number of affected photos on screen.
- [ ] Applying to seven photos writes seven independent caption rows, each editable alone afterwards.
- [ ] Tests: widget test of the default scope in both entry paths and of the displayed counts; unit tests of `caption_apply.dart` asserting append, replace, the recoverable previous value, and independence of each written row.

# 106 — Context: hierarchy, bar and inheritance

**Phase** 11 · Context  |  **Depends on** [037](../03-design-system/037-app-chip.md), [041](../03-design-system/041-app-dialog-service.md), [052](../04-data-layer/052-projects-table.md), [054](../04-data-layer/054-records-table.md), [062](../04-data-layer/062-repository-interfaces.md), [066](../05-file-storage/066-project-folder-service.md), [075](../06-app-shell/075-status-line.md), [078](../07-account-and-settings/078-settings-store.md), [094](../09-templates/094-field-list-editor.md), [105](../10-reference-data/105-reference-data.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The whole context feature: immutable models for the hierarchy definition, the current values and named presets, with
the repository and the persistence that restore the active context when a project is opened, so it survives screen
changes, backgrounding and app restarts; a screen that chooses a project's levels from the template's field keys and
orders them by drag, zero levels being a valid configuration that leaves the rest of the feature dormant; the
always-visible breadcrumb of current values, the sheet that sets one level from recents, a reference dataset or free
text, and the sheet that pins any stickable non-hierarchical field — surveyor, funder, survey date — as a chip
beside the levels with the same prefill behaviour; pure rules that decide which lower levels a change to a higher
level clears, and the single confirmation that names them before anything is cleared; prefill of a new record from
the current context with source `CONTEXT`, the whole context kept as that record's snapshot so later changes cannot
rewrite history, the per-record override that touches nothing else, and the snapshot driving the folder tree its
photos land in; named presets saved and restored in one tap; and two settings, both off by default, that clear the
lowest level after a configurable idle interval and ask the operator to confirm the context after a configured
distance travelled.

## Files

Domain — models and pure rules:

- `frontend/lib/features/context/domain/context_state.dart` (new)
- `frontend/lib/features/context/domain/context_cascade.dart` (new)
- `frontend/lib/features/context/domain/context_application.dart` (new)
- `frontend/lib/features/context/domain/context_override.dart` (new)
- `frontend/lib/features/context/domain/context_folder_link.dart` (new)
- `frontend/lib/features/context/domain/context_auto_clear.dart` (new)
- `frontend/lib/features/context/domain/context_movement_prompt.dart` (new)

Data — repository and persistence:

- `frontend/lib/features/context/data/context_repository_impl.dart` (new)
- `frontend/lib/features/context/data/context_persistence.dart` (new)

Presentation — the hierarchy editor, the bar, its sheets and the presets:

- `frontend/lib/features/context/presentation/context_hierarchy_screen.dart` (new)
- `frontend/lib/features/context/presentation/context_bar.dart` (new)
- `frontend/lib/features/context/presentation/context_picker_sheet.dart` (new)
- `frontend/lib/features/context/presentation/pinned_fields_sheet.dart` (new)
- `frontend/lib/features/context/presentation/context_preset_save.dart` (new)
- `frontend/lib/features/context/presentation/context_preset_list.dart` (new)

## Contract

```dart
class ContextLevel {
  const ContextLevel({required this.fieldKey, required this.order, this.datasetId});
  final String fieldKey;
  final int order;
  final String? datasetId;
}

class ContextState {
  const ContextState({this.levels = const [], this.values = const {}, this.pinned = const {}});
  final List<ContextLevel> levels;
  final Map<String, String> values; // fieldKey -> value, levels only
  final Map<String, String> pinned; // fieldKey -> value, non-hierarchical pins
  bool get isEmpty => levels.isEmpty && pinned.isEmpty;
}

class ContextPreset {
  const ContextPreset({required this.id, required this.name, required this.values, required this.pinned});
}
```

`context_repository_impl.dart` implements the `ContextRepository` interface declared in
[062](../04-data-layer/062-repository-interfaces.md) and publishes nothing beyond it.

## Steps

1. Build the data layer: the three models in `domain/`, the mappers both ways between each model and its context table
   rows, and the repository and persistence in `data/`. Load the stored context for a project as part of opening it,
   before the first screen that reads it builds, and persist on every change rather than on a lifecycle callback.
2. Build the hierarchy screen. Offer the template's field keys from the field list editor
   [094](../09-templates/094-field-list-editor.md); a key already used as a level is not offered twice. Drag to
   order, each level binding exactly one field key, and persist through `ContextRepository` on each change, including
   the removal of every level.
3. Build the bar. Render levels as `AppChip` with separators, pins after them and visibly marked as pins; tapping a
   chip opens the picker for that level or pin. Truncate the longest middle value first on narrow widths; the bar
   never grows past two lines and is hidden entirely when the context is empty.
4. Build the two sheets. The picker lists recent values for that level first, then dataset search where the level is
   bound to a reference dataset — the lookup path of [105](../10-reference-data/105-reference-data.md) — then an
   explicit "use this value" for free text. Offer pinning only for the fields the template marks stickable
   [095](../09-templates/095-field-add-basic.md).
5. Add cascade clearing. Compute the affected levels from the hierarchy order — everything below the changed level,
   ignoring pins — then confirm once through `AppDialogService`, in the specification's wording, naming each level
   that will clear and its current value. Apply the change and the clears as one write; declining leaves every level,
   including the changed one, untouched.
6. Apply context to records and to the folder path. Write every level and pin into `record_fields` with source
   `CONTEXT`, then store the whole context as the record's snapshot. An edit marks the field overridden on that
   record and leaves the project context and every other record untouched. Feed the record's own snapshot — not the
   live context — to the photo path builder of [066](../05-file-storage/066-project-folder-service.md).
7. Add presets. Saving captures every level value and pin currently set, under a name unique within the project, and a
   repeat name asks before overwriting. The list shows presets most recently used first, with their values as the
   subtitle. Applying sets the preset's values in one write, clears the levels the preset does not name, and shows no
   cascade confirmation because the operator chose the whole set.
8. Add the two optional settings last. Read the idle interval and the movement distance from the settings store
   [078](../07-account-and-settings/078-settings-store.md); both features stay inert until switched on. Auto-clear
   fires at most once per idle period, clears only the lowest level, and shows one undo toast that restores the
   cleared value. The movement prompt activates only where GPS is already enabled and location permission already
   granted through the permissions service; it asks for confirmation and never changes the context itself.

## Constraints

- Models live in `domain/` as pure Dart; the implementation and every Drift import stay in `data/`
  (FE-STR-05, FE-STATE-05).
- The cascade, application, override, folder-link, auto-clear and movement-prompt rules stay pure Dart too: they
  return the levels or the decision affected, and the caller shows the dialog or the toast (FE-STR-05).
- Models are immutable with `copyWith`; no mutable collection escapes (FE-CODE-04).
- Level names, level values and preset names are template content stored as user data, never interface text, and are
  never sent to the localisation catalogue (FE-L10N-07).
- Chips, separators, sheets, the reorderable list, list rows and empty states come from the design system; no bespoke
  chip, sheet or drag affordance, and the preset empty state names applying a preset as the next action
  (FE-CONS-01, FE-THEME-01, FE-SIMP-11).
- The bar reads the size class from `core/`; it never measures the screen itself (FE-RESP-02).
- Every chip and sheet row is a 48dp target with a semantic label (FE-A11Y-01, FE-A11Y-02).
- One confirmation, never a chain, with a safe default and a way out (FE-SIMP-07).
- The prefilled value is raw evidence: an override writes a new value beside it with an audit entry, never over it
  (FE-SEC-08, FE-SEC-09).
- Path segments derived from context values stay ASCII and filesystem-safe (FE-L10N-11).
- No location is read, and no location permission requested, while the movement prompt is off (FE-SEC-07).
- Both optional settings default to off and are justified by the specification, not by taste (FE-SIMP-12).
- Time and distance come from injected services so tests need no real clock or fix (FE-STR-11).

## Definition of done

- [ ] A project with no defined levels loads an empty `ContextState` and writes no rows.
- [ ] A project with no hierarchy shows no context bar anywhere and behaves as if the feature were absent.
- [ ] Reopening the app resumes the same district, facility and department for the open project.
- [ ] Reordering or removing a level persists immediately and survives leaving the screen.
- [ ] The bar fits a 320dp-wide phone with long facility names without wrapping to a third line.
- [ ] Setting a facility takes two taps on the second visit to it.
- [ ] A survey date pinned once applies to every record afterwards without being retyped.
- [ ] Changing district never leaves a stale facility or department attached to new records.
- [ ] Declining the cascade confirmation changes nothing at all, including the level that was being set.
- [ ] Ten records captured in one room all carry the same three values with no typing.
- [ ] Correcting one record's department moves neither the operator's context nor any other record.
- [ ] The on-disk tree mirrors the specification's example exactly for a three-level context.
- [ ] Moving between two rooms costs one tap each way.
- [ ] Saving a preset under an existing name asks before overwriting and never silently replaces a preset.
- [ ] With both optional settings off, the context never changes on its own and no location call is made anywhere.
- [ ] Undo after an auto-clear restores the cleared value exactly.
- [ ] Tests: unit round-trip mapper tests for `ContextState`, `ContextLevel` and `ContextPreset`.
- [ ] Tests: repository test against an in-memory database asserting the context reloads after a simulated restart.
- [ ] Tests: widget test of `context_hierarchy_screen.dart` covering zero levels, a three-level hierarchy, reorder
      persistence and a repository write failure.
- [ ] Tests: golden of `context_bar.dart` at three widths with long values and at 200 percent text scale.
- [ ] Tests: widget tests of `context_picker_sheet.dart` and `pinned_fields_sheet.dart` covering no recents, dataset
      search, free-text entry and a repository failure.
- [ ] Tests: unit tests of `context_cascade.dart` over zero-, one- and three-level hierarchies and over a change to
      the lowest level, with no Flutter binding.
- [ ] Tests: unit tests asserting value and source on a new record, and that the project context and sibling records
      are unchanged after an override.
- [ ] Tests: integration test capturing into a three-level context and asserting the resulting folder path.
- [ ] Tests: widget tests of `context_preset_save.dart` and `context_preset_list.dart` covering an empty list, a
      duplicate name, applying a preset that omits a level, and a repository failure.
- [ ] Tests: unit tests of `context_auto_clear.dart` and `context_movement_prompt.dart` with a fake clock and a fake
      location source, covering off, fired, undone and permission-denied, with no Flutter binding.

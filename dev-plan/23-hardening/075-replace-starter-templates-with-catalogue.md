# 075 — Replace the starter templates with the catalogue

**Phase** 23 · Hardening  |  **Depends on** [074](074-ship-full-template-catalogue.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The shipped library is the catalogue alone. The 23 starter templates of the former §13.4 (Equipment / Asset to
Generic Item) are removed, and the catalogue's assets move from `assets/templates/catalogue/` up into
`assets/templates/`, which then holds only the schema, the groups of §13.3, the catalogue index, the catalogue groups
and one file per category. The specification's §13.4–13.5 describe the library that remains.

Decisions:

- D1: the product owner chose to replace the starters outright, knowing their columns (99–212 per template) are not
  folded into the catalogue's; a project that needs one rebuilds it by extending a catalogue template (§13.6) or by
  importing a spreadsheet (§11.2).
- D2: `_groups.json` keeps the four groups of §13.3 by hand; the generated pack and context groups move to
  `_catalogue_groups.json` beside it, and the index stays `_catalogue.json`. The generator owns those two and every
  non-underscore JSON in the folder, so a run removes a template file nothing generates any more.
- D3: the template checker reads a file holding a `templates` array as a category of many templates and any other as
  one template, and reads `_catalogue_groups.json` beside `_groups.json`.
- D4: the loader drops `library()`; `entries()` and `template(key)` serve the catalogue alone, and every entry has a
  title, code, category and record type. `ShippedTemplateCategory` and the starter names and group titles in `Copy`
  go with the starters.
- D5: UNI-001 General observation is the universal fallback the success criteria name instead of Generic Item, and
  Meeting Mode (§28, task 017) builds on the Meeting record type, keeping its repeating rows in its own tables.

## Files

- `frontend/assets/templates/` (23 starter assets removed; catalogue assets moved up; `_catalogue_groups.json`)
- `frontend/tool/build_template_catalogue.dart`, `frontend/tool/check_templates.dart`, `frontend/pubspec.yaml`
- `frontend/lib/core/constants/template_assets.dart`, `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/templates/data/shipped_template_loader.dart`
- `frontend/lib/features/templates/domain/shipped_template_entry.dart`,
  `frontend/lib/features/templates/domain/shipped_template_category.dart` (removed)
- `frontend/lib/features/templates/presentation/shipped_picker_screen.dart`,
  `frontend/lib/features/templates/presentation/shipped_library_filter.dart`
- `app-write-up.md` (§13.4–13.7, §28.1, success criteria), `README.md`, `frontend/README.md`,
  `resources/template-library.md`, `dev-plan/17-meetings/017-meetings.md`

## Definition of done

- [x] `assets/templates/` holds `_schema.json`, `_groups.json`, `_catalogue.json`, `_catalogue_groups.json` and the 72
      category files, and nothing else; `catalogue/` and the 23 starter assets are gone.
- [x] The generator writes there, keeps the hand-kept files, and removes or flags a template file it did not write.
- [x] The checker counts 2,349 templates, all atomic.
- [x] The library lists, searches, filters, previews and copies the catalogue with no starter section.
- [x] Tests: `shipped_template_library_test`, `shipped_template_loader_test`, `shipped_template_entry_test`,
      `shipped_picker_screen_test`, `copy_test`, `build_template_catalogue_test`, `check_templates_test`;
      `shipped_template_category_test` removed with its source.

## Verification

`dart run tool/check_templates.dart` reports 2,349 templates, all atomic, and
`dart run tool/build_template_catalogue.dart --check` reports every generated file current.
`dart run tool/verify.dart --fast` fails the same three gates, with the same 17 failing tests and findings, as
before task 074; nothing here adds to them.

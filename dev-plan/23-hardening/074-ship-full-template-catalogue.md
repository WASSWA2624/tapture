# 074 — Ship the full template catalogue

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Ship every template of the planning catalogue `resources/templates.md` (2,349 templates, 72 categories, 17
supergroups, 26 shared archetype packs) in the app's library beside the 23 starter templates of §13.4. Each must
capture every field its record needs, be easy to find, and be copied into a project as an ordinary editable template
(§11.1, §13.6). The specification's new §13.7 describes the result.

Decisions, each the smallest that meets the ask without changing an existing behaviour:

- D1: the catalogue is generated, not hand-written. `frontend/tool/build_template_catalogue.dart` reads
  `resources/templates.md`, the typed packs in `frontend/tool/template_catalogue/packs.json` and the choice lists and
  per-field corrections in `frontend/tool/template_catalogue/field_rules.json`, and writes
  `frontend/assets/templates/catalogue/` plus the readable list `resources/template-library.md`. `--check` exits 1
  when a committed file has drifted.
- D2: a catalogue template is composed, not copied out in full: it inherits the four groups of §13.3, its category's
  context group (`context_<category>`, stickable, suggested RECOMMENDED) and its record type's pack
  (`pack_<pack>`), then adds its own starter fields (suggested RECOMMENDED, group `specific_details`). Packs and
  contexts live in `catalogue/_groups.json` and resolve through the same `inherits_groups` path the starter
  templates use. One asset per category keeps the web build to 74 requests, not 2,349.
- D3: every column is atomic (§13.1). Pack fields are typed by hand (`parties` becomes first, second and other party
  names; `dates` becomes start and end dates; `totals` becomes an amount and its currency; a `*_time` becomes a date
  and a time). Starter fields are typed by rules on their last word, with overrides for the 60-odd keys the rules
  would get wrong (19 `*_and_*` keys split in two, `address` narrowed to `street_address`, non-money `*_amount`,
  spans and odometers). Money gets a `_currency` companion and `MANUAL_ONLY` input, a stated measure gets a `_unit`
  companion, sizes split into length, width and height in millimetres, `*_timestamp` becomes `*_at`, a deadline
  becomes `*_date`, and prose an AI may rewrite is marked `refine`.
- D4: identity (§40) comes from the record type: each pack names its identity fields, so records of the same type
  match the same way in every category.
- D5: the library lists light entries, and resolves fields only for a preview or a copy. The catalogue index is built
  once off the UI thread through `runIsolate` (FE-PERF-02) and kept; a failed read is not kept. `library()` still
  returns the 23 starter templates; `entries()` lists all 2,372 and `template(key)` resolves any one of them.
- D6: names, category and record-type titles and guidance are catalogue data (FE-L10N-07): a catalogue asset keeps
  `name` as a `templates.<key>.name` key for the schema and carries its display `title`; field labels are
  `templates.catalogue.<key>` and resolve through `Copy.shippedLabel`.
- D7: the picker keeps its starter layout when only starter templates are listed, and adds area headings once
  catalogue templates are listed. Search matches name, code, category, area, record type, kind and own field labels,
  every word; the shared filter button (task 070) narrows by area, record type and tier. The list is built lazily.

## Files

- `resources/templates.md` (source, unchanged), `resources/template-library.md` (generated)
- `frontend/tool/build_template_catalogue.dart`, `frontend/tool/template_catalogue/packs.json`,
  `frontend/tool/template_catalogue/field_rules.json`
- `frontend/assets/templates/catalogue/` (generated: `_catalogue.json`, `_groups.json`, 72 category files),
  `frontend/assets/templates/_schema.json`, `frontend/pubspec.yaml`
- `frontend/tool/check_templates.dart`
- `frontend/lib/core/constants/template_assets.dart`, `frontend/lib/core/copy/copy.dart`
- `frontend/lib/features/templates/domain/shipped_template_entry.dart`,
  `frontend/lib/features/templates/domain/shipped_record_type.dart`,
  `frontend/lib/features/templates/domain/shipped_catalogue_category.dart`
- `frontend/lib/features/templates/data/shipped_template_loader.dart`, `frontend/lib/features/templates/templates.dart`
- `frontend/lib/features/templates/presentation/shipped_picker_screen.dart`,
  `frontend/lib/features/templates/presentation/shipped_library_filter.dart`
- `app-write-up.md` (§13.4, §13.7), `README.md`, `frontend/README.md`

## Definition of done

- [x] All 2,349 catalogue templates ship, one asset per category, each with its code, title, kind, record type,
      suggested privacy and tier, identity fields and inherited groups; every one resolves to 62–72 fields.
- [x] The template checker reads `assets/templates/catalogue/`, holds every catalogue template and group field to
      §13.1, names an unknown inherited group, reports each finding at its own line inside a category file, and
      counts 2,372 templates, all atomic.
- [x] The generator refuses a catalogue whose counts, packs, fields or guidance do not add up, writing nothing, and
      `--check` names every drifted file.
- [x] The loader lists 2,372 entries, starters first, indexes the catalogue off the UI thread once, resolves any
      template with its context fields stickable, its pack's choices, auto-fills and money input, and copies a
      catalogue template into a project at version 1 with labels and options resolved.
- [x] The library shows area and category headings, a code, record type and field count on each catalogue row;
      search and the area, record type and tier filters narrow it; the preview shows the category, record type,
      privacy and tier, guidance and every field under its group with type and requiredness; adding uses the
      catalogue title.
- [x] Tests: `build_template_catalogue_test`, `check_templates_test`, `shipped_template_loader_test`,
      `shipped_template_entry_test`, `shipped_record_type_test`, `shipped_catalogue_category_test`,
      `shipped_picker_screen_test`.

## Verification

`dart run tool/check_templates.dart` reports 2,372 templates, all atomic, and
`dart run tool/build_template_catalogue.dart --check` reports every committed file current.

`dart run tool/verify.dart --fast` on this change fails the same three gates, with the same 17 failing tests and the
same findings, as on the commit before it (test presence: the 47 files already owing a test; the architecture,
naming and structure findings and goldens already reported under task 070). Nothing here adds to them; the passing
counts rise by the new tests.

In Chromium, on the release web build (`--no-web-resources-cdn`) at 1280 by 900: the library lists the starter
templates under "Starter templates", then the catalogue under area and category headings; "borehole" finds four
templates in two areas with the count in the search field; the filter sheet offers area, record type and tier; the
preview of WAT-003 shows its category, record type, privacy and tier, the four guidance lines and 68 fields from
Record admin to Specific details.

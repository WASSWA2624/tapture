# 009 — Templates: record shapes with atomic columns, and requiredness the user owns

**Phase** 09 · Templates  |  **Depends on** [001](../01-orchestration/001-project-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The whole of `features/templates/`, plus the two pieces of `core/` this phase publishes: immutable `TemplateDef`,
`FieldDef` and `TemplateRow` with three-value `Requiredness`, a total Drift mapper and `TemplateRepositoryImpl` behind
the repository port the data layer published, so every later phase reads and writes templates through those three types
alone; the field type registry that describes each of the nineteen §12.1 types by its editor, validator, normaliser and
storage-and-export form, which capture, review, validation and export read instead of switching on the type themselves;
the asset schema and the `check_templates.dart` gate that refuses a shipped template whose columns are not atomic, and
the twenty-three §13.5 templates plus the four §13.3 inherited groups that pass it; the runtime loader and library
picker that turn one of those assets into a project-owned template at version 1 in two taps; the template list with its
blank create and its duplicate; the field list that is the only place fields are managed, with reorder, a delete that
retires values instead of destroying them, and the three-question add flow whose collapsed Advanced section carries
§12.2 in full alongside the validation-rule and choice-option editors; the required-columns screen where a project
overrules a shipped template's suggested requiredness for a whole template in one version bump; the one `FieldEditor`
in `core/widgets/` every feature edits a field value through; the identity-field and output-column settings; versioning
with a recorded diff and a migration screen that shows what will move before any record moves; versioned template JSON
that carries a template to another project or device and behaves identically at the other end; the `core/import`
pipeline that opens a workbook off the UI thread, finds its header row and proposes a type, unit and option list per
column, the confirmation screen that turns that into a template beside a byte-identical copy of the original, and the
predefined rows, row aliases and checklist an operator works through; and the per-template detection profile that
decides which template a photo belongs to.

## Files

The model and the field types:

- `frontend/lib/features/templates/domain/template_def.dart` (new)
- `frontend/lib/features/templates/domain/field_def.dart` (new)
- `frontend/lib/features/templates/domain/template_row.dart` (new)
- `frontend/lib/features/templates/domain/field_type_registry.dart` (new)
- `frontend/lib/features/templates/data/template_mapper.dart` (new)
- `frontend/lib/features/templates/data/template_repository_impl.dart` (new)

The shipped library, its schema and its checker:

- `frontend/assets/templates/_schema.json` (new)
- `frontend/assets/templates/_groups.json` (new)
- `frontend/assets/templates/*.json` (new — one per template, named by `template_key`)
- `frontend/lib/core/constants/template_assets.dart` (new)
- `frontend/lib/features/templates/data/shipped_template_loader.dart` (new)
- `frontend/lib/features/templates/presentation/shipped_picker_screen.dart` (new)
- `frontend/tool/check_templates.dart` (new)
- `frontend/test/tool/check_templates_test.dart` (new)

The template list:

- `frontend/lib/features/templates/presentation/template_list_screen.dart` (new)
- `frontend/lib/features/templates/presentation/template_create_screen.dart` (new)
- `frontend/lib/features/templates/presentation/template_duplicate_action.dart` (new)

The field editors:

- `frontend/lib/features/templates/presentation/field_list_screen.dart` (new)
- `frontend/lib/features/templates/presentation/field_reorder.dart` (new)
- `frontend/lib/features/templates/presentation/field_delete_action.dart` (new)
- `frontend/lib/features/templates/presentation/field_add_sheet.dart` (new)
- `frontend/lib/features/templates/presentation/field_advanced_section.dart` (new)
- `frontend/lib/features/templates/presentation/field_validation_editor.dart` (new)
- `frontend/lib/features/templates/presentation/field_options_editor.dart` (new)
- `frontend/lib/features/templates/presentation/required_columns_screen.dart` (new)
- `frontend/lib/features/templates/presentation/requiredness_controller.dart` (new)
- `frontend/lib/core/widgets/fields/field_editor.dart` (new)

Identity, output columns, versioning and portability:

- `frontend/lib/features/templates/presentation/identity_fields_screen.dart` (new)
- `frontend/lib/features/templates/presentation/output_mapping_screen.dart` (new)
- `frontend/lib/features/templates/domain/template_versioning.dart` (new)
- `frontend/lib/features/templates/presentation/template_migration_screen.dart` (new)
- `frontend/lib/features/templates/data/template_json.dart` (new)
- `frontend/lib/features/templates/presentation/template_import_action.dart` (new)

The spreadsheet path:

- `frontend/lib/core/import/workbook_reader.dart` (new)
- `frontend/lib/core/import/header_detection.dart` (new)
- `frontend/lib/core/import/type_inference.dart` (new)
- `frontend/lib/features/templates/presentation/xlsx_mapping_screen.dart` (new)
- `frontend/lib/features/templates/data/xlsx_template_import.dart` (new)
- `frontend/lib/features/templates/data/predefined_rows_import.dart` (new)
- `frontend/lib/features/templates/presentation/row_aliases_screen.dart` (new)
- `frontend/lib/features/templates/presentation/checklist_screen.dart` (new)

Detection:

- `frontend/lib/features/templates/presentation/detection_profile_screen.dart` (new)

## Contract

```dart
enum Requiredness { required, recommended, optional }

class TemplateDef {
  final String id, templateKey, name;
  final int version;
  final List<FieldDef> fields;
  final List<String> identityFieldKeys;
  final List<TemplateRow> rows;
}

class FieldDef {
  final String fieldKey, label;
  final FieldType type;
  final Requiredness requiredness;
  // §12.2 in full: defaultValue, unit, helpText, inputMode, stickable, contextLevel,
  // autoFill, refine, options, group, outputColumn, requiredWhen, hidden.
}

class TemplateRow {
  final String rowKey, label;
  final int? sourceRowNumber;     // the original spreadsheet line, kept for write-back
  final List<String> aliases;
}

enum FieldType {
  text, longText, number, decimal, currency, percentage,
  date, time, dateTime, boolean, choice, multiChoice, lookup,
  barcode, photoReference, documentReference, gpsLocation, signature, computed,
}

abstract interface class FieldTypeRegistry {
  // editor widget, validator, normaliser, storage-and-export form — one entry per type
  FieldTypeEntry entryFor(FieldType type);
}

final templateRepositoryProvider = Provider<TemplateRepository>(...);

Future<int> main(List<String> args)  // tool/check_templates.dart: scans
                                     // frontend/assets/templates/, exits non-zero on any violation

class RequirednessController {
  void set(String fieldKey, Requiredness value);
  void setHidden(String fieldKey, bool hidden);
  Future<TemplateVersion> commit();   // one version bump for the whole pass
}

class FieldEditor extends ConsumerWidget {
  final FieldDef field;
  final FieldValue value;
  final ValueChanged<FieldValue> onChanged;
}
```

## Steps

### The model and the field types

1. Land the domain model and the repository. `TemplateDef`, `FieldDef` and `TemplateRow` carry every field attribute of
   §12.2 — `defaultValue`, `unit`, `helpText`, `inputMode`, `stickable`, `contextLevel`, `autoFill`, `refine`,
   `options`, `group`, `outputColumn`, `requiredWhen` and `hidden` — and requiredness is the three-value enum, never a
   bool, because a user may move a field between all three (§13.2). `TemplateRepositoryImpl` sits behind the repository
   port the data layer published in 004 · Local database; the source file cited a later number, which names lookup
   matching rather than a port. Mappers are total: columns the table has stay on the row, and the attributes it has no
   column for — `helpText`, `requiredWhen`, `hidden`, `group`, the identity flag, recommended, the auto-fill kind and
   `templateKey` — live in JSON, in the validation document under `_tapture` and in the detection document for
   `templateKey`, so a round-trip drops nothing. The barrel publishes `templateRepositoryProvider` and an in-memory
   fake later screens test against. One public class per file puts `FieldDef`, `TemplateRow` and the mapper in files of
   their own, with `Requiredness`, `FieldType`, `InputMode` and `AutoFill` declared after the class in `field_def.dart`.
2. Land the field type registry: one entry per §12.1 type, each supplying four behaviours — editor widget, validator,
   normaliser, and storage-and-export form. All nineteen are registered by name so the completeness test can assert the
   set: text, long text, number, decimal, currency, percentage, date, time, date-time, boolean, choice, multi-choice,
   lookup, barcode, photo reference, document reference, GPS location, signature and computed. Most reuse an existing
   design-system field from 003 · Design system — the source file cited data-layer table numbers here. Three do not and
   are declared as such: signature draws on screen and stores the result as an image beside the record's evidence,
   computed is read-only and evaluated by the validation engine of 015 · Data quality, and GPS location is filled
   during capture in 012 · Capture. Presentation supplies the widget builder so `domain/` imports no Flutter, and the
   registry stays additive: adding a type later is one entry and one switch case, not edits across ten files.

### The shipped library

3. Land the asset schema and the atomicity checker, before a single template is authored. `_schema.json` names
   `schema_version`, `template_key`, `name`, `kind`, `identity_fields`, `inherits_groups`, `fields[]` and
   `child_rows[]`, each field carrying `field_key`, `label`, `type`, `required`
   (`REQUIRED | RECOMMENDED | OPTIONAL`), optional `required_when`, `unit`, `options`, `group` and `help`, and the
   nineteen registry type names. `required` in an asset is recorded as a suggested default only; the schema carries no
   notion of a requiredness the user cannot change (§13.2). `check_templates.dart` fails an asset when a `field_key` is
   not `snake_case` or is not unique within the template; when a label or key packs two facts — a `/`, `&`, ` and `, or
   a `+` joining two nouns (`make_model`, `district_and_village`); when a measured field has no unit, either in the key
   suffix (`_mm`, `_kg`, `_sqm`, `_percent`, `_c`) or in `unit`; when a money field has no `_currency` companion; when
   a `*_refined` field has no `*_raw` companion, or the pair is not both declared (§32); when a `*_code` field has no
   `*_name` companion where the template declares a lookup; when a date column is anything other than one date
   (`_date`, `_at`), or a boolean is not `is_*`, `has_*`, `*_present`, `*_required` or `*_confirmed`; when
   `identity_fields` names a key the template does not define; and when `required_when` references a field the template
   does not define. Every message names the file and the line. One valid fixture and one deliberately broken fixture
   per rule ship with it, under `frontend/test/tool/fixtures/templates/` so they cannot fail the default
   `assets/templates/` scan. The checker is wired in as the `templates` gate of `dart run tool/verify.dart`, so a
   broken asset blocks a build.
4. Author the library. `_groups.json` holds the four §13.3 groups — `record_admin`, `location_context`, `evidence` and
   `review` — which every template references by name rather than repeating. Twenty-three `{template_key}.json` assets
   transcribe §13.4 and §13.5 exactly, field keys, types, groups, choice lists, identity keys and child rows:

   ```text
   equipment_asset      medical_equipment    ict_equipment       vehicle_plant      furniture_fitting
   building_facility    room_space           utility_point       stock_item         inspection_check
   work_order           meter_reading        person_beneficiary  staff_member       household_survey
   land_parcel          plant_tree           livestock_animal    document_record    meeting
   event_activity       incident_report      generic_item
   ```

   `medical_equipment`, `ict_equipment`, `vehicle_plant` and `furniture_fitting` set `derives_from: equipment_asset`
   and reuse the parent's keys, so the columns they share export into the same columns. `required` comes from the §13.5
   markers — `*` is REQUIRED, `+` is RECOMMENDED, everything else OPTIONAL — and the required set stays small enough
   that a first capture is never blocked (§13.2). `meeting` carries its child rows — agenda item, attendee, apology,
   decision, action item — rather than flattening them into columns; each is stored as a `TemplateRow` with a row key,
   a label and the nested field shapes in its metadata. `identity_fields` is declared per template exactly as §13.5
   lists it: incident identity uses `exact_location_description` rather than a packed `location`, and keys such as
   `room_code` and `site_code` count as defined because the checker resolves `inherits_groups` and `derives_from`
   before judging them. `generic_item` omits `category` so it has ten columns and one required field, `item_name`.
   Every label is a localisation key, and `TemplateAssets` names the schema, the groups and every library path so no
   call site carries a literal.

### The editors

5. Land the template list, blank create and duplicate. A project's templates render as `AppListTile` rows with field
   and record counts, through `AsyncValueView` for loading, empty, error and offline, with the empty state offering the
   shipped-library picker as its next action. Row actions are open, duplicate, export and delete, the last offered only
   where no record uses the template and confirmed with the count named. Blank creation asks for a name and nothing
   else, then lands on the field list, so one added field makes the template usable. Duplicating copies fields,
   predefined rows and row aliases; records stay attached to the original and the copy starts with none. Record counts
   arrive through `templateRecordCountsProvider`, which defaults to none until the records feature has a watch to give
   it.
6. Land the runtime loader and the library picker. The loader reads each packed asset, validates it against
   `_schema.json`, resolves its §13.3 inherited groups and its `derives_from` parent, and then copies a project-owned
   `TemplateDef` at version 1; the asset itself is never mutated. `ShippedPickerScreen` lists the library by its §13.4
   kinds, previews the resolved field list before adding, and allows renaming on add, so a new project is capture-ready
   in two taps without anyone building a field. Assets are reached through generated constants, and labels arriving
   from an asset stay localisation keys resolved at render time: `Copy.shippedLabel` resolves a key from its last
   segment and `Copy.shippedTemplateName` holds the twenty-three library names until ARB files exist.
   `FakeShippedTemplateLoader` is the fake later tests use.
7. Land the field list editor, reorder and delete. This list is the only place fields are managed: each field is an
   `AppListTile` with label, type and an `AppStatusPill` requiredness badge, keyboard-navigable, with a
   move-up/move-down affordance beside the drag. Drag order is capture order and export order and writes list order
   only — stored values and `outputColumn` stay put. Delete warns through the shared dialog service with the count of
   records holding a value for the field, then marks those values retired rather than deleting them, and they export as
   retired. Value counts come through `fieldValueCountsProvider`, which defaults to none until capture has a watch.
   Requiredness reuses the status pill with `Copy.fieldRequired`, Recommended and Optional as its labels.
   `/templates/:id/fields/new` and `/templates/:id/fields/:fieldKey` open the add sheet.
8. Land the add-and-edit flow. The three questions of §12.3 — **Label**, **Type**, **Required?** — default every other
   §12.2 attribute. The field key generates from the label, unique and stable, held to the atomicity conventions of
   §13.1: `snake_case`, one fact, and the unit appended where the value is measured. REQUIRED, RECOMMENDED and OPTIONAL
   are three equal choices defaulting to OPTIONAL, because requiredness is the user's decision at every point and never
   the app's (§13.2). A label that packs two facts (`Make / Model`, `Address`) is questioned once with an offer to
   split it, and the user can still insist. Advanced stays collapsed and carries every attribute the flow defaulted —
   default value, unit, help text, input mode, stickable, context level, auto fill, refine and identity — plus the two
   that decide whether a field applies at all, `required_when` and `hidden`. `required_when` takes a simple expression
   over other fields of the same template, `fault_present == true`, validated against the field list as it is typed and
   previewed in plain language. `hidden` keeps the field out of the capture screen and out of every export while
   preserving values already captured under it (§18); unhide restores them and it is never a delete. Validation rules
   cover pattern, length, range and required-with, with ready-made serial, asset-tag and registration patterns and a
   custom option carrying a live test box. Choice options can be added, reordered, renamed and retired; a rename
   updates the label only and never the stored code. Any change saved here bumps the template version (§18).
9. Land the required-columns screen, the one place a project decides for a whole template at once which columns it
   insists on. The template renders as one scrollable list: field label on the left, three radio columns — REQUIRED,
   RECOMMENDED, OPTIONAL — and a **Hide** toggle on the right, rows grouped by the template's field groups with the
   §13.3 inherited groups collapsed by default, and the shipped default shown beside a changed value so a user can see
   what they moved and put it back. `RequirednessController.set`, `setHidden` and `commit` write the whole pass as one
   `TemplateRepository.save`, which is the existing version bump, so a multi-field pass is one version and not one per
   field (§18). A field made REQUIRED blocks approval and never capture: an incomplete record still saves and lands in
   NEEDS_REVIEW, older records keep their status, and a hidden field leaves capture and export while keeping every
   value already captured. The controller lives in `presentation/` because FE-STR-03 names only data, domain and
   presentation; `RequirednessView` is a public typedef rather than a second class, and `toggleGroup` plus the
   capture-status statics sit on the controller so the widgets stay thin.
10. Land the one field editor widget, in `core/widgets/fields/`, which edits any field value using the editor its type
    declares in the registry and is reused by review, records, capture and duplicate resolution. It never switches on
    the type: `fieldEditorBindingsProvider` is the registry port, overridden with `templateFieldEditorBindings`, and
    `FieldEditorField` is the core-facing record the template type maps onto so core imports no feature. An edit sets
    source MANUAL, marks the value verified, and appends an audit entry carrying the previous value — including a
    change back to the original value. `FieldValue` lives beside it in core until the records feature owns it.

### Identity, versioning and portability

11. Land the two template-level column settings reached from the field list. Identity is a multi-select over the
    template's existing fields with one sentence explaining what it changes; it rewrites `identityFieldKeys` and
    `FieldDef.identity` through one `TemplateRepository.save`. A shipped template arrives with `identity_fields`
    already set (§13.5) and this screen edits that set rather than inventing it. Output columns auto-assign unique
    headers from labels for templates built in the app and for shipped ones, and stay manually overridable for
    templates imported from a workbook, where the column letters already exist and are never invented.
    `duplicateOutputColumn` refuses a mapping in which two fields claim the same column. Both screens write through the
    template repository and bump the version like any other structural change (§18).
12. Land versioning and record migration. The version bumps on any structural change — a field added, removed,
    retyped, renamed, reordered, hidden, or its requiredness changed — and what changed between the two consecutive
    versions is recorded. A captured record keeps the version it was captured under and keeps rendering and exporting
    under it. `TemplateVersioning` holds the diff and the migration, pure Dart with no Flutter or Drift import, and
    `TemplateRepository.save` stays the one bump. The migration screen lists fields added, removed and retyped with the
    count of records each affects and requires explicit confirmation before any record moves; the move is one durable
    transaction, so a failure part-way leaves every record on its old version.
13. Land the JSON representation. `TemplateJson` stamps `schema_version` 1 and carries every §12.2 attribute, identity
    keys, predefined rows and row aliases. Decode validates shape, types and field-key uniqueness before touching the
    database, rejects an unknown schema version with a plain message rather than a partial import, and always inserts
    a new project-owned template at version 1, never overwriting an existing one silently. `TemplateImportAction` is
    empty with no payload, renders `AppErrorState` on a failed decode including a schema 2 file, and persists only
    after a successful decode.

### The spreadsheet path

14. Land the `core/import` pipeline. `WorkbookReader` opens an XLSX or a CSV off the UI thread through the isolate
    runner from 002 · Foundation services — the source file cited the page scaffold's number here — reporting sheet
    names, used range, merged cells and existing rows, and streaming large files rather than loading them whole. A
    password-protected file and a corrupt one each fail with copy naming which it is. `HeaderDetection` scores
    candidate header rows by text density and uniqueness, so a title block scores below a row of unique labels, and
    exposes the chosen row for confirmation. `TypeInference` proposes a type, unit and option list per column from
    sample values — numbers, dates, booleans, small option sets and identifier patterns — resolving each to a type
    declared in the field type registry, and returns every inference as a suggestion with no authority of its own, for
    the caller to present as editable. The reference-data import of 010 · Reference data reuses these same three
    files; the source file cited a meetings-phase number for it.
15. Land the mapping confirmation and the template it creates. `XlsxMappingScreen` shows one `AppListTile` per
    spreadsheet column — source header on the left, proposed field, type and rule on the right — every row editable and
    every row skippable, and writes nothing, no template and no copied file, until the user confirms. On confirm,
    `XlsxTemplateImport` saves the template with the sheet name, the header row and the column letters, so export
    writes back into the same cells, and copies the chosen workbook into the project's `templates/` folder
    byte-identically and once, through the project folder service.
16. Land predefined rows, aliases and the checklist. `PredefinedRowsImport` maps the identifier and label columns onto
    checklist rows and keeps the original spreadsheet row number on every row for write-back. `RowAliasesScreen` edits
    aliases per row and imports them in bulk by overlaying a chosen column, which is how a local name such as
    "BP machine" reaches "Blood Pressure Machine". `ChecklistScreen` is a virtualised list grouped by context, showing
    found and missing through `AppStatusPill` and "Found 12 of 40" per group, and starting a capture for a row when it
    is tapped.

### Detection

17. Land the detection profile editor. `DetectionProfileScreen` edits the object classes, keywords, identifier
    patterns, linked datasets and negative keywords on `TemplateDef.detection`. Every template carries a profile: a
    shipped one arrives with its kind, identity labels and field patterns as defaults, and a blank one keeps an empty
    profile that matches nothing and still works. Negative keywords exclude a template the positive keywords would
    otherwise have matched, so two similar templates can be told apart. Identifier patterns reuse the validation
    patterns a field already declares rather than restating them.

## Constraints

- Columns are atomic: one fact per column, `snake_case` keys, the unit in the key where the value is measured, a
  `*_raw` companion for every `*_refined` field, and no label that packs two facts. The checker enforces it on every
  asset and the add flow warns on it in the app (§13.1, §32).
- Requiredness belongs to the user. A shipped `required` marker is a suggested default only; REQUIRED, RECOMMENDED and
  OPTIONAL are three equal choices a field may be moved between at any point, and neither the schema, the model nor a
  screen carries a requiredness the user cannot change (§13.2).
- A REQUIRED column blocks approval, never capture. Nothing this phase publishes can stop a record being saved
  (rule 3 of the standard).
- Nothing under `features/templates/domain/` imports Flutter or Drift; the mapper lives in `data/`, and template
  versioning is pure Dart for the same reason (FE-STR-05).
- Models are `const`-constructible and copy-with, never mutated in place (FE-CODE-04).
- Presentation reaches templates only through the domain interface, never a DAO or a Drift row (FE-STATE-05).
- The registry names editors through a builder supplied by presentation, and every editor resolves to a catalogue
  widget; no type introduces a parallel field control (FE-STR-05, FE-CONS-01).
- Type names match `lib/core/naming/domain_names.dart`, and every `type` declared in an asset resolves to a registry
  entry; a synonym or an unknown type is a violation (FE-CONS-07).
- `check_templates.dart` is a `tool/` script with no Flutter dependency, runnable from a clean checkout (FE-STR-01).
- Asset labels are localisation keys, never English strings baked into the asset, and are resolved at render time
  rather than stored as display strings (FE-L10N-01, FE-L10N-07).
- Labels, help text, option names, keywords and identifier patterns a user types are template content stored as user
  data, not localisation keys (FE-L10N-07).
- Assets are declared in `pubspec.yaml` and reached through generated constants, never a literal path (FE-STR-12).
- Every screen assembles existing catalogue parts: rows are `AppListTile`, requiredness and found-or-missing render
  through `AppStatusPill` with a shape as well as a colour, counts render through the shared formatters, and no screen
  invents a radio grid or a table widget (FE-CONS-01, FE-CONS-06, FE-CONS-09, FE-THEME-05).
- Loading, empty, error and offline render through `AsyncValueView`, and an empty state offers the next action
  (FE-CONS-04, FE-SIMP-11).
- A destructive confirmation comes from the shared dialog service and names the consequence and the count
  (FE-SIMP-07).
- Advanced is closed by default and a simple template never meets it; the two-fact warning offers *keep anyway* and
  never blocks the save (FE-SIMP-06, FE-SIMP-08).
- Reorder is reachable without a drag gesture, the radio grid stays usable at 200 percent text, and every cell and
  affordance is named for a screen reader (FE-A11Y-01, FE-A11Y-02, FE-A11Y-03).
- `FieldEditor` lives in `core/widgets/` and the import pipeline in `core/import/`, so neither imports a feature
  (FE-STR-04).
- Version bumping calls the one versioning service rather than a second implementation (FE-STR-09), and every
  structural change bumps it (§18).
- Every edit through `FieldEditor` writes an audit entry carrying the previous value, including a change back to the
  original value (FE-SEC-09).
- Migration is a single durable transaction: a failure part-way leaves every record on its old version (FE-STATE-07).
- An imported template file and an imported workbook are untrusted input: shape, types and field-key uniqueness are
  validated before anything is persisted, and cell text, labels and option names are data — never markup, never
  instructions, never interpolated into a query (FE-SEC-05, FE-SEC-06).
- The copied workbook is raw evidence: written once, never rewritten in place (FE-SEC-08).
- Parsing, header scoring and inference run off the UI thread and stream large files rather than loading them whole,
  and the checklist is virtualised so a forty-row and a four-thousand-row template scroll the same
  (FE-PERF-02, FE-PERF-03, FE-PERF-07).
- Deleting a field and hiding a field each destroy nothing: values are retired or preserved, and retired values still
  export (rule 1 of the standard).

## Definition of done

### The model and the field types

- [x] `TemplateDef`, `FieldDef` and `TemplateRow` carry every attribute of §12.2, with requiredness a three-value enum.
- [x] The mapper is total in both directions: an attribute the table has no column for is carried in JSON rather than
      dropped.
- [x] Every later task in this phase reads and writes templates through those three types alone, and no screen sees a
      DAO or a Drift row.
- [x] Capture, review, validation and export all read behaviour from the field type registry rather than switching on
      type.
- [x] Every type of §12.1 is present, and a type missing any of its four behaviours fails the registry test.
- [x] Adding a field type is one entry in the registry, not edits across ten files.
- [x] Tests: `frontend/test/features/templates/template_mapper_test.dart` round-trips every attribute; repository tests
      run against an in-memory database and ship the fake later tasks use (FE-STATE-10).
- [x] Tests: a unit test over the declared set asserting all nineteen types are present and that each entry supplies
      all four behaviours.
- [x] The Contract above is implemented exactly — the model, the registry, the checker entry point, the requiredness
      controller and the field editor — with nothing else made public.

### The shipped library

- [x] A column named `make_model`, `address` or `cost` without a currency fails the checker with a file and a line.
- [x] A `caption_refined` without `caption_raw` fails the checker.
- [x] `identity_fields` or `required_when` naming a key the template does not define fails the checker, and
      `inherits_groups` and `derives_from` are resolved before that judgement is made.
- [x] An asset carries no notion of a requiredness the user cannot change: `required` is a suggested default only.
- [x] The checker runs inside `dart run tool/verify.dart` and blocks a build, and its broken fixtures live under
      `frontend/test/tool/fixtures/templates/` so they never fail the library scan.
- [x] All twenty-three templates exist and `dart run tool/check_templates.dart` is green on every one of them.
- [x] No template repeats a field that belongs to an inherited group, and the four derived templates reuse their
      parent's keys rather than inventing near-duplicates.
- [x] `generic_item` has ten columns and one required field, so capture can start before the shape is decided.
- [x] `meeting` carries its child rows rather than flattening them into columns.
- [x] Tests: `frontend/test/tool/check_templates_test.dart` runs the checker over the valid fixture and over one
      deliberately broken fixture per rule, asserting file and line in each message.
- [x] Tests: a test that every asset parses, validates against `_schema.json`, and resolves its inherited groups and
      identity keys.

### The editors

- [x] A blank template is immediately usable after one added field.
- [x] Duplicating leaves the original's records on the original, and the copy carries its fields, rows and aliases.
- [x] Delete is offered only for a template no record uses.
- [x] A new project is capture-ready without building anything: pick, preview, add.
- [x] Editing a copied template cannot affect the library, and a second copy of the same asset is unaffected by the
      first.
- [x] The field list is the only place fields are managed.
- [x] Reordering never changes stored values or output column mapping.
- [x] Deleting a field never loses captured data: retired values survive and export as retired.
- [x] A field is added in under ten seconds and lands OPTIONAL unless the user says otherwise; a two-fact label is
      questioned once and the user can still insist.
- [x] `required_when` naming an unknown field is refused at edit time, not at capture time.
- [x] Hiding a field removes it from capture and export, and a later unhide brings its old values back intact.
- [x] A validation rule can be tested against a sample value before saving, and renaming an option does not rewrite
      historical records.
- [x] A shipped template can be re-scoped from forty suggested columns to eight required ones in a single pass.
- [x] Changing requiredness produces exactly one new template version, and records captured under an earlier version
      are not marked incomplete.
- [x] A field made REQUIRED blocks approval, never capture: an incomplete record still saves and lands in
      NEEDS_REVIEW.
- [x] Every correction made through the shared field editor is recorded with what it replaced, including a change back
      to the original value.
- [x] Editing through that widget yields the same behaviour in review, records, capture and duplicate resolution.
- [x] Tests: widget tests of `template_list_screen.dart` and `template_create_screen.dart` covering empty and failure
      states; a test that duplication copies fields, rows and aliases and copies no records.
- [x] Tests: repository tests for `shipped_template_loader.dart` against an in-memory database, plus the fake later
      tests use; widget test of `shipped_picker_screen.dart` covering its empty and failure states.
- [x] Tests: widget test of `field_list_screen.dart` covering empty and failure states and a reorder; a test that
      retired values survive a delete and export as retired.
- [x] Tests: unit tests over key generation and collision handling, `required_when` expression validation, the
      hide/unhide value round trip, and option rename leaving stored codes untouched; widget tests of
      `field_add_sheet.dart`, `field_validation_editor.dart` and `field_options_editor.dart` covering empty and failure
      states.
- [x] Tests: widget test over the three-radio grid and the hide toggle, including 200 percent text; unit test that a
      multi-field pass commits one version and that a record captured earlier stays captured.
- [x] Tests: widget test of `field_editor.dart` asserting the audit row and the MANUAL source after an edit, across at
      least one text, one choice and one date field.

### Identity, versioning and portability

- [x] Duplicate detection has an explicit, visible configuration rather than an implied one.
- [x] Two fields cannot claim the same output column.
- [x] A template imported from a workbook keeps its column letters and never has one invented for it.
- [x] Old records still render and export correctly after a template edit, and keep their captured version.
- [x] No record is migrated without the user first seeing the added, removed and retyped fields and the counts.
- [x] A migration that fails part-way leaves every record on its old version.
- [x] An exported template imports elsewhere with identical behaviour, rows and aliases included.
- [x] An unknown schema version imports nothing and says why in plain language.
- [x] Tests: widget tests of `identity_fields_screen.dart` and `output_mapping_screen.dart` covering empty, failure and
      save states; unit test rejecting a duplicate output column.
- [x] Tests: unit test that a record keeps its captured version across a bump and that the recorded diff matches the
      change; widget test of `template_migration_screen.dart` covering empty and failure states.
- [x] Tests: round-trip export-and-import test over a template exercising every attribute; widget test of
      `template_import_action.dart` covering empty and failure states, including the rejected-version path.

### The spreadsheet path

- [x] A twenty-sheet workbook opens without freezing the interface.
- [x] A workbook with a title block above the header still maps correctly.
- [x] A password-protected file and a corrupt one each fail with copy naming which it is.
- [x] Suggestions are visibly suggestions and always editable.
- [x] Nothing is imported until the user confirms the mapping.
- [x] The original file on disk is byte-identical to the one the user chose.
- [x] A template created this way exports back into the same sheet, header row and column letters.
- [x] Rows import with their spreadsheet positions preserved, so a later export writes back to the right line.
- [x] "BP machine" reliably matches "Blood Pressure Machine".
- [x] The operator can see what is still missing in the current room.
- [x] A forty-row and a four-thousand-row checklist scroll the same.
- [x] Tests: reader test against a fixture workbook including a corrupt and a password-protected file; unit tests over
      fixtures with and without title rows; unit tests of inference over mixed sample columns.
- [x] Tests: widget test of `xlsx_mapping_screen.dart` covering empty and failure states and the skip path; hash
      comparison test of the workbook before and after import.
- [x] Tests: repository tests for `predefined_rows_import.dart` against an in-memory database, plus the fake later
      tests use; widget tests of `row_aliases_screen.dart` and `checklist_screen.dart` covering empty and failure
      states.

### Detection

- [x] Every template carries a profile, with sensible defaults for shipped ones and a working empty one for blanks.
- [x] A negative keyword demotes a template that the positive keywords would have matched.
- [x] Tests: widget test of `detection_profile_screen.dart` covering empty and failure states; unit test that a
      negative keyword excludes an otherwise-matching profile.

## Out of scope

- Anything on the required-columns screen other than requiredness and visibility; labels, types and options stay in
  the field editor of step 8.
- Evaluating a computed field, which the validation engine of 015 · Data quality owns, and filling a GPS field, which
  012 · Capture owns. This phase declares both types and leaves them unfilled.
- Reference-data import over the same workbook reader, which 010 · Reference data owns; this phase publishes the three
  `core/import` files it reuses and imports no dataset of its own.
- The ARB files the shipped labels resolve against, which the localisation pass owns; shipped labels resolve through
  `Copy` until then.

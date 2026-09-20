# 090 — Shipped template asset format and atomicity checker

**Phase** 09 · Templates  |  **Depends on** [088](088-template-model.md), [089](089-field-type-registry.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The JSON shape a shipped template asset must have, and the checker that refuses one whose columns are not atomic.
Specification §13.1 and §13.2 are the source of truth; this task turns them into a schema and a failing test, before
a single template is authored in 156.

## Files

- `frontend/assets/templates/_schema.json` (new)
- `frontend/tool/check_templates.dart` (new)
- `frontend/test/tool/check_templates_test.dart` (new)

## Contract

```dart
Future<int> main(List<String> args)  // scans frontend/assets/templates/, exits non-zero on any violation
```

## Steps

1. Define the asset schema: `schema_version`, `template_key`, `name`, `kind`, `identity_fields`, `inherits_groups`,
   `fields[]` and `child_rows[]`. Each field carries `field_key`, `label`, `type`, `required`
   (`REQUIRED | RECOMMENDED | OPTIONAL`), optional `required_when`, `unit`, `options`, `group` and `help`.
2. Record that `required` in an asset is a **suggested default only** — the schema must not carry any notion of a
   requiredness the user cannot change (§13.2).
3. Write the checker. It fails an asset when any of the following is true:
   - a `field_key` is not `snake_case`, or is not unique within the template;
   - a label or key packs two facts into one column — a `/`, `&`, ` and `, or a `+` joining two nouns
     (`make_model`, `district_and_village`);
   - a measured field has no unit, either in the key suffix (`_mm`, `_kg`, `_sqm`, `_percent`, `_c`) or in `unit`;
   - a money field has no `_currency` companion;
   - a `*_refined` field has no `*_raw` companion, or the pair is not both declared (§32);
   - a `*_code` field has no `*_name` companion where the template declares a lookup;
   - a date column is anything other than one date (`_date`, `_at`), or a boolean is not `is_*`, `has_*`,
     `*_present`, `*_required` or `*_confirmed`;
   - `identity_fields` names a key the template does not define;
   - `required_when` references a field the template does not define.
4. Ship fixtures: one valid asset, and one deliberately broken asset per rule above.
5. Wire the checker into `dart run tool/verify.dart` so a broken asset blocks a build.

## Constraints

- Every declared `type` resolves to an entry in the field type registry; an unknown type is a violation (FE-CONS-07).
- The checker is a `tool/` script with no Flutter dependency, runnable from a clean checkout (FE-STR-01).

## Definition of done

- [x] A column named `make_model`, `address` or `cost` without a currency fails the checker with a file and a line.
- [x] A `caption_refined` without `caption_raw` fails the checker.
- [x] The checker runs inside `dart run tool/verify.dart` and blocks a build.
- [x] Tests: `frontend/test/tool/check_templates_test.dart` runs the checker over the valid fixture and over one deliberately broken fixture per rule, asserting file and line in each message.
- [x] Contract above is implemented exactly, with nothing else made public.

## Out of scope

- Authoring the shipped templates themselves; that is 156.
- Loading assets at runtime; that is 157.

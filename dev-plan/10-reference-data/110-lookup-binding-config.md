# 110 — Configure a lookup field

**Phase** 10 · Reference data  |  **Depends on** [095](../09-templates/095-field-add-basic.md), [105](105-dataset-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The screen that binds a template field to a dataset: which dataset, which columns are matched, which dataset columns
fill which template fields, whether fuzzy matching is allowed and above what threshold, and what happens when
nothing matches.

## Files

- `frontend/lib/features/templates/presentation/lookup_binding_screen.dart` (new)

## Contract

```dart
class LookupBinding {
  final String datasetId;
  final List<String> matchColumns;        // tried in order
  final Map<String, String> fillMapping;  // dataset column -> template field key
  final bool fuzzyEnabled;
  final double fuzzyThreshold;
  final NoMatchBehaviour onNoMatch;       // leaveEmpty | promptAddRow | warn
}
```

## Steps

1. Offer only the datasets in the current project, and only the template's own fields as fill targets.
2. Match columns are ordered: the key column first, then the name column, then anything else the user adds.
3. Refuse a mapping that fills a field the template does not define, or two dataset columns into one field.

## Constraints

- The binding is stored on the `FieldDef` as a §12.2 attribute, so changing it bumps the template version (§18).

## Definition of done

- [ ] The configuration matches the specification example exactly, dataset and fill mapping included.
- [ ] A mapping naming an unknown field or filling one field twice is refused at configuration time.
- [ ] Tests: widget test of `lookup_binding_screen.dart` covering empty and failure states; unit test rejecting an unknown fill target and a duplicate target.
- [ ] Contract above is implemented exactly, with nothing else made public.

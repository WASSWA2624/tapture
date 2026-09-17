# 200 — CSV, JSON and data dictionary writers

**Phase** 18 · Export  |  **Depends on** [089](../09-templates/089-field-type-registry.md), [155](../13-processing/155-evidence-linking.md), [195](195-value-formatter.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The three text outputs: CSV, one file per template, UTF-8 with a byte-order mark and a configurable delimiter; JSON,
the full-fidelity export carrying raw, refined and final values with their provenance; and the data dictionary that
lets an analyst read either without the app.

## Files

- `frontend/lib/core/export/csv_writer.dart` (new)
- `frontend/lib/core/export/json_writer.dart` (new)
- `frontend/lib/core/export/data_dictionary.dart` (new)

## Steps

1. CSV: quote fields containing the delimiter, quotes or newlines; escape embedded newlines; when more than one
   template produces a file, zip the set.
2. JSON: stream records to the sink one at a time; include values raw, refined and final, provenance from 288,
   confidence, evidence references, context path and the template version each record was captured under.
3. Dictionary: emit key, label, type, unit, options with their codes, required flag and description for every field of
   every exported template, taken from the registry of 154.

## Constraints

- All three writers stream to file and never hold the whole document in memory (FE-PERF-07).
- Values are rendered only through `ExportValueFormatter` (FE-CONS-09).

## Definition of done

- [ ] A CSV file round-trips through a standard reader with delimiters, quotes and newlines intact.
- [ ] A ten-thousand-record project exports to JSON without memory exceeding its baseline budget.
- [ ] The dictionary describes every field present in the CSV and JSON output, so an analyst needs no other source.
- [ ] Tests: unit tests of `csv_writer.dart` (round trip through a CSV reader), `json_writer.dart` (schema validation plus a measured memory assertion) and `data_dictionary.dart` (every exported field described), with no Flutter binding.

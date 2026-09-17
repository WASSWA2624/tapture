# 193 — Export request model and pre-export validation

**Phase** 18 · Export  |  **Depends on** [041](../03-design-system/041-app-dialog-service.md), [060](../04-data-layer/060-exports-table.md), [062](../04-data-layer/062-repository-interfaces.md), [170](../15-data-quality/170-validation-engine.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

An export is fully described by a serialisable `ExportRequest` — formats, scope, column options, extras and the
resulting file list — so a stored request replays the same export exactly. `ExportValidation` inspects the records a
request selects, reports the incomplete and unapproved ones, and returns the operator's choice before any writer runs.

## Files

- `frontend/lib/features/exports/domain/export_request.dart` (new)
- `frontend/lib/features/exports/domain/export_validation.dart` (new)

## Contract

```dart
enum ExportFormat { xlsx, csv, json, pdf, zip }

class ExportRequest {
  const ExportRequest({
    required this.projectId,
    required this.formats,
    required this.scope,
    required this.columns,
    required this.extras,
    this.markedIncomplete = false,
  });
  factory ExportRequest.fromJson(Map<String, Object?> json);
  Map<String, Object?> toJson();
}

enum ExportGateChoice { fixNow, excludeThem, exportAnyway }

class ExportValidationReport {
  const ExportValidationReport(this.incomplete, this.unapproved);
  final List<String> incomplete;
  final List<String> unapproved;
  bool get isClean;
}
```

## Steps

1. Keep every field of the request in `toJson`, including the resolved file list, so history can re-run it.
2. Read validation results from 315 rather than re-implementing field checks.
3. On `exportAnyway`, set `markedIncomplete` so the writers can stamp the fact into the output itself.

## Constraints

- `export_request.dart` and `export_validation.dart` stay pure Dart: no Drift, Flutter or HTTP import (FE-STR-05).
- The gate presents one decision through the shared dialog service; it never builds its own dialog (FE-CONS-05).

## Definition of done

- [ ] An `ExportRequest` survives a JSON round trip unchanged, field for field.
- [ ] An export marked incomplete says so inside the produced file, not only in the app.
- [ ] Each of `fixNow`, `excludeThem` and `exportAnyway` leads to the outcome it names.
- [ ] Tests: unit tests of `export_request.dart` (round trip) and `export_validation.dart` (all three gate paths and the clean path), with no Flutter binding.

# 280 — Backlog report generator

**Phase** 25 · Testing and release  |  **Depends on** [006](../01-orchestration/006-plan-integrity-checker.md), [244](../23-hardening/244-field-trial.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The tool that turns everything unbuilt, every friction entry and every waived release gate into one ordered backlog
report nobody has to assemble by hand.

## Files

- `frontend/tool/backlog_report.dart` (new)

## Contract

```dart
Future<int> main(List<String> args)  // writes build/backlog.md
```

## Steps

1. Scan the plan for unticked tasks, grouped by phase, with dependencies resolved to titles.
2. Merge in friction-log entries and waived release gates, each with its date and source.
3. Emit one ordered report naming, for every deferred item, the reason it was deferred and the trigger for revisiting it.

## Definition of done

- [ ] Running the tool after a release produces a backlog ordered by phase, with every waiver from the release record
      present and attributed.
- [ ] An item with no stated deferral reason is reported as a defect in the report itself, not omitted.
- [ ] Tests: `frontend/test/tool/backlog_report_test.dart` runs over a fixture plan and asserts grouping, ordering and
      the inclusion of a waived gate and a friction entry.

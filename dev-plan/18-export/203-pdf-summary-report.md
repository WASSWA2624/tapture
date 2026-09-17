# 203 — Project summary and variance reports

**Phase** 18 · Export  |  **Depends on** [177](../15-data-quality/177-variance-computation.md), [201](201-pdf-engine.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The two project-level reports. The summary counts records by context, template, condition and status with simple
charts. The variance report sets as-recorded against as-found and lists what is missing from the register and what was
found but is not in it.

## Files

- `frontend/lib/core/export/pdf/summary_report.dart` (new)
- `frontend/lib/core/export/pdf/variance_report.dart` (new)

## Steps

1. Aggregate counts once per report and pass totals to the engine's cover slots.
2. Draw charts from the same token palette as the app; a chart never carries information its table does not.
3. Read variance rows from 331; present matched, missing and not-in-register as three labelled sections.

## Constraints

- Charts are readable without colour: label every series (FE-THEME-05).
- Aggregation happens off the UI thread with the rest of the render (FE-PERF-02).

## Definition of done

- [ ] Summary counts by context, template, condition and status agree with the same counts shown in the app.
- [ ] The variance report names every missing and every not-in-register item, with its register key.
- [ ] Tests: golden test of one page of each report, plus unit tests of `summary_report.dart` aggregation and of `variance_report.dart` section membership against a seeded fixture.

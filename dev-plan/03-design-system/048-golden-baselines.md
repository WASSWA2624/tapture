# 048 — Golden test baselines for the catalogue

**Phase** 03 · Design system  |  **Depends on** [016](../01-orchestration/016-test-presence-checker.md), [047](047-widget-gallery.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The golden harness and the committed baselines that lock the appearance of the whole catalogue, so an unintended styling
change fails a test rather than reaching a field worker.

## Files

- `frontend/test/design_system/golden_harness.dart` (new)
- `frontend/test/design_system/goldens/` (new)

## Contract

```dart
Future<void> expectGolden(WidgetTester t, Widget w, String name, {List<AppThemeMode> modes});
```

## Steps

1. `expectGolden` wraps the widget in the resolved theme for each requested mode, pumps to a settled frame and compares
   one file per mode, defaulting to light, dark and outdoor.
2. Pin the test font and disable animation so a baseline is reproducible on any machine.
3. Generate and commit baselines for every catalogue widget and for the gallery index.

## Constraints

- Golden coverage is per widget and per mode: light, dark and outdoor for every design-system widget (FE-TEST-02).
- Pump to an explicit condition; a fixed delay in a golden test is a defect that will flake (FE-TEST-07).
- The suite runs in continuous integration and is never skipped or weakened to make a change pass (FE-TEST-06).

## Definition of done

- [ ] An unintended styling change fails the suite and names the widget and mode that moved.
- [ ] Regenerating baselines on a clean tree produces no diff.
- [ ] Tests: the golden suite covers every widget built in this phase in all three modes and runs in continuous
      integration; a fixture proving a deliberate one-pixel change is caught.

## Out of scope

- Screen-level goldens for feature phases; each feature phase commits its own.

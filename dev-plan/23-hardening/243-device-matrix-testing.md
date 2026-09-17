# 243 — Device matrix runner

**Phase** 23 · Hardening  |  **Depends on** [236](236-responsive-audit.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The script that runs the integration suite across the configured device classes, captures the field-critical timings on
each, and fails the run when one regresses against the stored baseline.

## Files

- `frontend/tool/devices.yaml` (new)
- `frontend/tool/device_matrix.dart` (new)
- `frontend/test/tool/device_matrix_test.dart` (new)

## Contract

```dart
Future<int> main(List<String> args)  // --devices low,mid,tablet
```

## Steps

1. Declare the device classes, their identifiers and their per-metric tolerances in `devices.yaml`.
2. Run the integration suite on each attached device, capturing cold start, shutter latency, export duration and merge
   duration.
3. Write a comparison report against the stored baseline and exit non-zero when a metric regresses beyond its
   tolerance, naming device, metric and margin.
4. Skip an unattached class with a named warning rather than passing silently as if it had run.

## Constraints

- The runner reports every regression it finds, not just the first.
- Tolerances live in `devices.yaml`, never in Dart (FE-CODE-09).

## Definition of done

- [ ] A regression on the low-end device fails the run, naming the metric and the margin; an unattached device class is
      reported, not ignored.
- [ ] Tests: `frontend/test/tool/device_matrix_test.dart` parses fixture output and asserts the comparison logic,
      including a within-tolerance pass, a beyond-tolerance failure and a missing-device warning.

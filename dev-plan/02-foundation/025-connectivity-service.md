# 025 — Connectivity service

**Phase** 02 · Foundation services  |  **Depends on** [021](021-result-and-failures.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

`frontend/lib/core/network/connectivity_service.dart` reports online, metered or offline, and reports offline whenever
the user's manual override is on, whatever the radio says.

## Files

- `frontend/lib/core/network/connectivity_service.dart` (new)

## Contract

```dart
enum NetworkState { online, metered, offline }  Stream<NetworkState> watch();
```

## Steps

1. Combine the platform connectivity stream with the settings override so offline always wins.

## Constraints

- One switch stops every outbound call, and capture, editing, review and export continue unaffected (FE-SEC-04).
- The plugin is reached only through this service, which ships a fake source for tests (FE-STR-11, FE-TEST-03).
- The platform subscription is released on dispose (FE-STATE-09).

## Definition of done

- [x] Enabling the manual override reports offline regardless of the radio state.
- [x] `metered` is distinguished from `online`, so later tasks can defer an upload without inventing their own check.
- [x] Tests: `frontend/test/core/network/connectivity_service_test.dart` uses a fake source and asserts the override wins from every radio state.

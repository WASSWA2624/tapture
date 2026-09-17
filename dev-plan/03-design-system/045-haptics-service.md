# 045 — Haptics service

**Phase** 03 · Design system  |  **Depends on** [004](../01-orchestration/004-folder-scaffold.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Named haptic patterns behind one interface, so capture, save, warning, error and selection each feel distinct and no
feature calls the platform directly.

## Files

- `frontend/lib/core/feedback/haptics.dart` (new)

## Contract

```dart
abstract interface class Haptics {
  void shutter(); void save(); void warning(); void error(); void selection();
}
```

## Steps

1. Ship the interface, the platform implementation and a recording fake that tests assert against.
2. Read the system haptics setting once and suppress every pattern when it is off.

## Constraints

- Platform vibration is reached only through this service; no feature calls `HapticFeedback` directly (FE-STR-11).
- The system haptics and reduced-motion settings are honoured, never overridden (FE-A11Y-08).
- Capture and save both confirm by touch, and the two are distinguishable without looking at the screen (FE-A11Y-09).

## Definition of done

- [ ] Shutter and save feel distinct in the hand, and every pattern is silent when the system setting is off.
- [ ] Tests: unit tests against the recording fake asserting each named pattern fires once, and that all five are
      suppressed when haptics are disabled.

## Out of scope

- Sound feedback; no audible confirmation is part of this task.

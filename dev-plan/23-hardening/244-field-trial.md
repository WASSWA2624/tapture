# 244 — In-app friction log

**Phase** 23 · Hardening  |  **Depends on** [022](../02-foundation/022-logger-service.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The one-tap "something went wrong here" action a field tester uses during a trial, and the local log behind it that the
tester exports by hand.

## Files

- `frontend/lib/features/settings/domain/friction_log.dart` (new)
- `frontend/lib/features/settings/presentation/friction_log_button.dart` (new)

## Contract

```dart
Future<Result<void>> logFriction({required String screen, String? note, bool withScreenshot = false});
```

## Steps

1. Record screen, timestamp, operator, project, the last user action and an optional note and screenshot, all on the
   device.
2. Expose the action from the overflow menu on every screen while the trial flag is enabled, and from nowhere when it is
   off.
3. Capture happens without leaving the current task: the sheet takes an optional note and dismisses back to the same
   screen state.
4. Export the whole log with its screenshots as one file from settings, through the log export action (028).

## Constraints

- Nothing is transmitted: no upload, no crash service, no analytics (FE-SEC-10).
- Screenshots are stored beside the log under the app's own storage and are removed with it.

## Definition of done

- [ ] A tester flags a problem in one tap and stays exactly where they were, with a draft record untouched.
- [ ] The log stays local until the tester exports it, and the export contains every entry and every screenshot.
- [ ] Tests: test that an entry captures screen, project and last action; test that export contains every entry and
      screenshot; test that the action is absent with the trial flag off.

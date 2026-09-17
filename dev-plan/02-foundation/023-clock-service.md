# 023 — Clock, identifiers and device identity

**Phase** 02 · Foundation services  |  **Depends on** [004](../01-orchestration/004-folder-scaffold.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The three primitives every audit row and merge depends on: an injectable UTC clock, a time-ordered UUIDv7 generator
built on it, and the device identifier that is generated once and never regenerated.

## Files

- `frontend/lib/core/time/clock.dart` (new)
- `frontend/lib/core/ids/uuid_service.dart` (new)
- `frontend/lib/core/device/device_identity.dart` (new)

## Contract

```dart
abstract interface class Clock { DateTime nowUtc(); DateTime today(); Duration get offset; }
class SystemClock implements Clock;  class FixedClock implements Clock;
abstract interface class IdService { String newId(); }  class UuidV7Service implements IdService;
Future<String> deviceId();  Future<DeviceDescriptor> deviceDescriptor();
```

## Steps

1. Expose `nowUtc`, `today` and the device offset; provide `FixedClock` for tests.
2. Record on `Clock` the rule that `DateTime.now` is never called directly anywhere else.
3. Implement UUIDv7 from the clock plus a random tail, with a deterministic sequence implementation for tests.
4. Generate the device identifier once, persist it, and never regenerate it — not on restart, not on update.
5. Expose model, operating system version and application version as `DeviceDescriptor` for audit rows.

## Constraints

- `UuidV7Service` and `deviceId()` take their `Clock` and `IdService`; nothing here reads the system clock or generates an id inline (FE-STR-11).
- All three ship a hand-written fake, so later tests never touch the platform (FE-STATE-10, FE-TEST-03).
- `DeviceDescriptor` carries model, OS version and app version only — no advertising identifier, no IMEI, no hardware serial (FE-SEC-07, FE-SEC-10).

## Definition of done

- [x] A test freezes time with `FixedClock` and asserts a stamped value exactly.
- [x] Identifiers generated in order sort in order as strings, and ten thousand contain no duplicate.
- [x] The device identifier is identical after a restart and after an app update.
- [x] Tests: `frontend/test/core/time/clock_test.dart` covers both clock implementations; `frontend/test/core/ids/uuid_service_test.dart` asserts ordering, uniqueness and format; `frontend/test/core/device/device_identity_test.dart` asserts persistence across two reads and the descriptor fields.

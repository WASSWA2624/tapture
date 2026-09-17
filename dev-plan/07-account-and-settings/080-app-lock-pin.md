# 080 — App lock: PIN and biometric unlock

**Phase** 07 · Account and settings  |  **Depends on** [027](../02-foundation/027-secure-storage-service.md), [079](079-settings-shell.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

An optional lock on launch and resume. The user sets, changes or removes a PIN; only a salted hash of it ever exists,
in secure storage. Where the device supports biometrics the lock offers them, with the PIN as the fallback — a
biometric failure never leaves the app unlocked.

## Files

- `frontend/lib/features/settings/domain/app_lock.dart` (new)
- `frontend/lib/features/settings/data/pin_lock.dart` (new)
- `frontend/lib/features/settings/data/biometric_lock.dart` (new)
- `frontend/lib/features/settings/presentation/app_lock_screen.dart` (new)
- `frontend/lib/app/route_guards.dart` (edit)

## Contract

```dart
enum LockAttempt { unlocked, wrong, lockedOut, unavailable }

abstract interface class AppLock {
  bool get isEnabled;
  Future<Result<void>> setPin(String pin);
  Future<Result<void>> removePin(String currentPin);
  Future<LockAttempt> unlockWithPin(String pin);
  Future<bool> biometricsAvailable();
  Future<LockAttempt> unlockWithBiometrics();
}
```

## Steps

1. Store a salt and a salted hash through `secure_storage.dart` under a declared `SecretKey`. The PIN itself is never
   written, never logged and not retained after the comparison.
2. Rate-limit attempts with an escalating backoff persisted alongside the hash, so a restart does not reset the
   counter. Return `LockAttempt.lockedOut` while the backoff is running and show the remaining time.
3. Offer the biometric path only when `biometricsAvailable()` is true. Failure, cancellation or an unenrolled device
   returns to the PIN prompt; nothing falls through to an unlocked app.
4. Gate launch and resume as one entry in the router's guard chain, so the lock covers every route including deep links.
5. State the recovery path on screen in plain language: nobody can reset the PIN, the data stays on the device, and no
   control here erases anything.

## Constraints

- The PIN never reaches the database, the preferences map, an export or a log line (FE-SEC-01, FE-SEC-10).
- `biometric_lock.dart` wraps the platform plugin behind an interface with a hand-written fake; no screen and no test
  touches the plugin (FE-STR-11, FE-TEST-03).
- Forgetting the PIN must not offer, imply or trigger a data wipe (FE-SIMP-09).

## Definition of done

- [ ] With the lock on, launch and resume both prompt; turning it off deletes the hash and the backoff state.
- [ ] Failing or cancelling biometrics falls back to the PIN, never to no lock.
- [ ] The attempt backoff survives a restart, and the screen explains the recovery path without offering a wipe.
- [ ] Tests: unit tests of hashing, of the persisted backoff across a simulated restart, and of the biometric-to-PIN
  fallback against fakes for `secure_storage.dart` and the biometric wrapper; a widget test of set, change and remove.

# 069 — Storage headroom guard

**Phase** 05 · File storage  |  **Depends on** [065](065-storage-root.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A watched free-space state that warns while capture continues, and blocks new capture only once a further photo would
risk losing data, always naming the next action.

## Files

- `frontend/lib/core/files/storage_guard.dart` (new)

## Contract

```dart
enum HeadroomState { ample, low, critical }

abstract interface class StorageGuard {
  Stream<HeadroomState> watch();
  Future<Result<HeadroomState>> check();
}
```

## Steps

1. Read free space on the storage root's volume, poll on app resume and before each capture session, not per shutter.
2. Report `low` below 500 MB and `critical` below 100 MB, both thresholds from `AppConstants`.
3. At `low`, warn once per session and let capture proceed; at `critical`, refuse a new capture with an explanation and a
   route to export and to cache cleanup.
4. Let an in-flight save complete even at `critical`, so a photo already taken is never discarded.

## Constraints

- Only genuine risk of loss blocks; the `low` warning is dismissible and offers *keep capturing* (FE-SIMP-08).
- The refusal names the consequence and the next action in plain language, rendered from a typed `Failure`
  (FE-SIMP-10, FE-CONS-11).
- Free space is read through a `core/` service with a fake, never a plugin call from a feature (FE-STR-11).

## Definition of done

- [ ] A device below 500 MB warns once and still captures; below 100 MB new capture is refused with a route to export.
- [ ] A save already under way at the critical threshold completes and writes its row.
- [ ] A full device never produces a truncated photo or a record without its file.
- [ ] Tests: `frontend/test/core/files/storage_guard_test.dart` drives a fake free-space source across both thresholds,
      asserts one warning per session, the refusal at critical, and completion of an in-flight save.

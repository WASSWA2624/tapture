# 077 — Operator profile

**Phase** 07 · Account and settings  |  **Depends on** [044](../03-design-system/044-app-form-scaffold.md), [051](../04-data-layer/051-tombstones-table.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The local operator identity every capture is attributed to before enrolment exists, held in the device profile row and
shaped so signing in later adopts it rather than replacing it (§71.2). Authentication belongs to the backend (§70.1)
and no part of it appears here.

## Files

- `frontend/lib/features/settings/domain/operator_profile.dart` (new)
- `frontend/lib/features/settings/presentation/operator_profile_screen.dart` (new)
- `frontend/lib/core/db/tables/device_profile.dart` (edit)

## Contract

```dart
final class OperatorProfile {
  const OperatorProfile({required this.name, required this.initials, this.contact, this.accountId});
  final String name;
  final String initials;
  final String? contact;
  /// Filled by enrolment (498); null on every pre-backend install.
  final String? accountId;
}
```

## Steps

1. Fields on screen: name, initials, optional contact. No password, no PIN, no token and no credential.
2. Add the nullable `accountId` column to the device profile table in this task's migration, so enrolment fills it in
   without a schema change and without rewriting attribution already recorded.
3. Default the initials from the name and let the user override them; validate that the name is non-empty and the
   initials are one to three characters.
4. Build the form with `AppForm`, so the unsaved-changes guard and the error summary come from the design system.

## Constraints

- No credential of any kind is stored or validated here; secrets would belong in `secure_storage.dart` and this task
  writes none (FE-SEC-01, FE-SEC-02).
- The profile is one row that already exists after first launch; this screen updates it and never inserts a second
  (FE-STATE-06).

## Definition of done

- [x] Every record captured afterwards carries this operator name in its attribution.
- [x] The stored row has a nullable `accountId` from its first migration, and an upgraded database reads it as null.
- [x] Nothing on this screen authenticates anyone.
- [x] Tests: `frontend/test/features/settings/operator_profile_screen_test.dart` covers validation, save and the
  unsaved-changes guard; a migration test against an in-memory database asserts `accountId` exists and is null.

## Out of scope

- Sign-in, enrolment and role grants; task 267 owns them.

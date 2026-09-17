# 027 — Secure storage service

**Phase** 02 · Foundation services  |  **Depends on** [015](../01-orchestration/015-logging-checker.md), [021](021-result-and-failures.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

`frontend/lib/core/security/secure_storage.dart` is the only sanctioned home for keys and credentials, reached through
typed accessors over a closed `SecretKey` enum.

## Files

- `frontend/lib/core/security/secure_storage.dart` (new)

## Contract

```dart
Future<Result<void>> putSecret(SecretKey k, String v);  Future<Result<String?>> readSecret(SecretKey k);  Future<void> deleteAll();
```

## Steps

1. Wrap the platform secure storage; define `SecretKey` as a closed enum so no arbitrary key name can appear.
2. Assert in debug that no secret value is ever passed to the preferences store or the database.

## Constraints

- Secrets go here and nowhere else — never the database, logs, exports, bundles or preferences (FE-SEC-01).
- Nothing ships with a provider key; a key entered on the device is the administrator-permitted exception for a lone operator, not the default arrangement (FE-SEC-02).
- The plugin is reached only through this service, which ships a fake backing store (FE-STR-11, FE-TEST-03).

## Definition of done

- [ ] Secrets survive a restart and are absent from the database and every export.
- [ ] `deleteAll` leaves no readable residue for any `SecretKey`.
- [ ] Tests: `frontend/test/core/security/secure_storage_test.dart` uses a fake backing store and asserts isolation from the preferences store and the database.

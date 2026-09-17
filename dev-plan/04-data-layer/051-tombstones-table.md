# 051 — Tombstones, audit log and device profile tables

**Phase** 04 · Local database  |  **Depends on** [018](../01-orchestration/018-network-test.md), [023](../02-foundation/023-clock-service.md), [050](050-column-mixins.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The three device-local bookkeeping tables no feature owns: tombstones so a delete survives merge instead of being
resurrected, the audit log that replaces a server audit trail, and the single device profile row holding device id,
operator name and preferences. All three are written from inside the caller's transaction.

## Files

- `frontend/lib/core/db/tables/tombstones.dart` (new)
- `frontend/lib/core/db/tables/audit_log.dart` (new)
- `frontend/lib/core/db/tables/device_profile.dart` (new)

## Contract

```dart
Future<void> writeTombstone(
  Transaction tx, {
  required String entityType,
  required String entityId,
  required String reason,
});

Future<void> appendAudit(
  Transaction tx, {
  required String entityType,
  required String entityId,
  required AuditAction action,
  String? fieldKey,
  String? previousValue,
  String? newValue,
  String? reason,
});
```

## Steps

1. Tombstones: `entityType`, `entityId`, `deletedAt`, `deletedByDevice`, `reason`; unique on entity type plus entity id.
2. Wire `writeTombstone` into the `softDelete` hook left open by task 050, so the row and its tombstone share one
   transaction.
3. Audit log: `entityType`, `entityId`, `action`, `fieldKey`, `previousValue`, `newValue`, `reason`, `operator`,
   `device`, `at`; index on entity type plus entity id plus `at` for the record history view.
4. Device profile: `deviceId`, `operatorName`, preferences JSON; created on first launch, enforced single-row by a
   fixed primary key, never inserted twice.

## Constraints

- All three tables declare the shared merge columns through `MergeColumns` in the migration that creates them
  (FE-SEC-09).
- Audit rows are append-only: no update, no delete path, and they travel in bundles like any other data (FE-SEC-08,
  FE-SEC-09).
- Never write a field value, caption or transcript to a log sink while writing it to the audit table (FE-CODE-08).

## Definition of done

- [x] Deleting any entity produces exactly one tombstone, in the same transaction, and no hard delete anywhere.
- [x] Every value change writes exactly one audit row carrying both previous and new value.
- [x] The device profile row exists after first launch and a second launch does not duplicate it.
- [x] Tests: `frontend/test/core/db/tables/tombstones_test.dart` asserts delete-plus-tombstone atomicity and that a
      failed delete writes neither; `audit_log_test.dart` asserts an update records previous and new values;
      `device_profile_test.dart` asserts idempotent first-launch creation. All against an in-memory database, each
      covering its table's migration step.

# 224 — Destination abstraction and model

**Phase** 21 · Cloud upload  |  **Depends on** [027](../02-foundation/027-secure-storage-service.md), [062](../04-data-layer/062-repository-interfaces.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The one interface every destination backend implements, the persisted destination record and its repository. A row
carries kind, label, folder and a credential reference; the credential value itself exists only in secure storage.

## Files

- `frontend/lib/core/cloud/cloud_destination.dart` (new)
- `frontend/lib/core/db/tables/destinations.dart` (new)
- `frontend/lib/features/cloud/domain/destination_repository.dart` (new)

## Contract

```dart
enum DestinationKind { s3, googleDrive, oneDrive, dropbox, webdav, localFolder }

class Destination {
  const Destination({required this.id, required this.kind, required this.label, required this.folder,
      required this.credentialRef});
  final String id; final DestinationKind kind; final String label; final String folder; final String credentialRef;
}

abstract interface class CloudDestination {
  DestinationKind get kind;
  Future<Result<void>> check(Destination d);
  Future<Result<Uri>> send(Destination d, File file, {required String remoteName, int offset = 0,
      void Function(int sent, int total)? onProgress, CancellationToken? cancel});
}

abstract interface class DestinationRepository {
  Stream<List<Destination>> watchAll();
  Future<Result<void>> save(Destination d);
  Future<Result<void>> remove(String id);
}
```

## Steps

1. Resolve backends by `kind` through one registry map, so adding a backend is one entry rather than a branch at
   every call site.
2. Write only `credentialRef` to the destinations table; the value goes to secure storage under its `SecretKey`
   entry (037).
3. `send` reports progress, accepts a starting `offset` and honours cancellation, so 426 can resume a part-sent file.
4. `remove` deletes the row and its secret in one operation, leaving neither an orphan row nor an orphan credential.

## Constraints

- Networking imports stay under `core/cloud/`; nothing in `features/` holds a client (FE-SEC-03).
- No credential value reaches the database, logs, preferences, exports or bundles (FE-SEC-01).
- `destination_repository.dart` stays pure Dart with no Drift type in its signatures (FE-STR-05, FE-STATE-05).

## Definition of done

- [ ] A destination round-trips through the repository with no credential value anywhere in the database or logs.
- [ ] A `DestinationKind` with no registered backend fails at resolution with a named failure, not a null.
- [ ] Tests: `frontend/test/core/cloud/cloud_destination_test.dart` asserts the persisted row holds only
      `credentialRef`, that the registry resolves every kind, and that `remove` clears row and secret together.

## Out of scope

- The backends themselves; those are tasks 420 and 421.

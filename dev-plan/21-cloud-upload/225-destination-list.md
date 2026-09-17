# 225 — Destinations screen with test and removal

**Phase** 21 · Cloud upload  |  **Depends on** [027](../02-foundation/027-secure-storage-service.md), [038](../03-design-system/038-app-card.md), [224](224-destination-model.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One screen listing every configured destination with add, edit, connection test and removal. Removing a destination
purges its credential from secure storage in the same operation as the row.

## Files

- `frontend/lib/features/cloud/presentation/destination_list_screen.dart` (new)
- `frontend/lib/features/cloud/presentation/destination_remove_action.dart` (new)

## Steps

1. Each row uses `AppListTile` to show kind, label, folder and the outcome of the last connection check.
2. Add and edit collect the backend's fields, write the credential to secure storage and the row through
   `DestinationRepository`, and refuse to save until `CloudDestination.check` succeeds.
3. Removal asks once, then deletes row and secret through `DestinationRepository.remove`; a partial failure reports
   which half remains rather than reporting success.

## Constraints

- Credential fields are obscured, never logged and never echoed back into the form after saving (FE-SEC-01).
- The screen renders all four states, including a destination whose check last failed (FE-CONS-04).

## Definition of done

- [ ] A destination can be added, renamed, tested and removed without leaving the screen.
- [ ] After removal, secure storage holds no entry for that destination and re-adding the same label starts with no
      credential.
- [ ] Tests: widget test of `destination_list_screen.dart` over empty, populated, loading and failed-check states;
      test asserting secure storage no longer holds the entry after `destination_remove_action.dart` runs.

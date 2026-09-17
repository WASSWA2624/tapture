# 026 — Runtime permissions service

**Phase** 02 · Foundation services  |  **Depends on** [021](021-result-and-failures.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The one service that requests camera, microphone, location and storage, each with a rationale string and a recovery
path, so a denial is a typed failure rather than an exception or a dead screen.

## Files

- `frontend/lib/core/permissions/permissions_service.dart` (new)

## Contract

```dart
Future<Result<PermissionState>> request(AppPermission p);  Future<PermissionState> status(AppPermission p);
```

## Steps

1. Wrap each of the four permissions with request, status and a rationale string; on permanent denial, offer the settings page.

## Constraints

- No feature calls the permission plugin; this service is the only caller and ships a fake (FE-STR-11, FE-TEST-03).
- A denial returns `PermissionFailure` carrying its recovery action; no raw exception crosses the boundary (FE-CODE-06).
- Location is requested only where a project has enabled GPS, since GPS is off by default (FE-SEC-07).

## Definition of done

- [ ] A denied permission returns `PermissionFailure` with a recovery action, never an exception.
- [ ] A permanently denied permission offers the settings page rather than repeating the prompt.
- [ ] Tests: `frontend/test/core/permissions/permissions_service_test.dart` covers granted, denied and permanently denied for camera, microphone, location and storage.

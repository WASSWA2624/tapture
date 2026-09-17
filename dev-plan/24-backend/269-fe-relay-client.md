# 269 — App: change relay client and controls

**Phase** 24 · The minimal backend  |  **Depends on** [208](../19-bundles-and-merge/208-bundle-format.md), [218](../19-bundles-and-merge/218-merge-apply.md), [267](267-fe-backend-config.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Push and pull of encrypted change packages over the existing bundle and merge machinery, plus the per-project controls and
the queue view the relay rules require of the client.

## Files

- `frontend/lib/core/backend/relay_client.dart` (new)
- `frontend/lib/features/account/presentation/relay_settings_screen.dart` (new)
- `frontend/test/core/backend/relay_round_trip_test.dart` (new)
- `frontend/test/features/account/relay_settings_test.dart` (new)

## Steps

1. Build a delta bundle since the last acknowledged version with the existing writer, encrypt it with the project key,
   and push it with an idempotency key so a dropped connection cannot duplicate it.
2. Pull the packages this device has not acknowledged, decrypt them, and hand them to the existing merge preview and
   conflict flow untouched; acknowledge only after a merge has been applied.
3. Offer per-project enable, a schedule, Wi-Fi only, and a never-relay marking; relay stays off until a project manager
   turns it on.
4. Show queued, sent and purged packages, so what has left the device is always visible.

## Constraints

- Relay is the backend's one **optional** capability (§72): an organisation that never enables it must still have a
  complete, fully working product.
- Reuse the bundle writer and merge apply unchanged; a second encryption, diff or merge path here is a defect
  (FE-CONS-01, FE-STR-09).
- The project key stays in secure storage and never travels with a package (FE-SEC-01, FE-SEC-11).

## Definition of done

- [ ] Relayed packages merge through exactly the same preview and conflict path as a hand-carried bundle.
- [ ] Relay is off until a project manager turns it on, and a never-relay project offers no way to send.
- [ ] What has been queued, sent and purged is always visible for a project.
- [ ] Tests: an integration test relaying between two local databases through a fake server, including a replayed push;
      widget tests for each control and the queue view.

# 081 — Manual offline mode switch

**Phase** 07 · Account and settings  |  **Depends on** [025](../02-foundation/025-connectivity-service.md), [078](078-settings-store.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

One switch in settings that stops every outbound call while leaving capture, editing, review and export untouched.
It writes a single stored flag; `connectivity_service.dart` already folds that flag in and reports offline, so no
feature learns about the switch itself.

## Files

- `frontend/lib/features/settings/presentation/offline_switch.dart` (new)

## Steps

1. Write the override through `settings_store.dart`. This screen is its only writer; every reader asks
   `connectivity_service.dart` for `NetworkState`.
2. Work that would have gone online queues instead of failing, and the status line says the app is offline by choice
   rather than by radio.
3. Turning the switch off releases the queue; nothing is retried while it is on.
4. Say on screen, in one line, what keeps working: everything except sending.

## Constraints

- Offline is absolute — no feature may bypass the override, and the network boundary test from task 018 must still pass
  (FE-SEC-03, FE-SEC-04).
- One source of truth: nothing caches its own copy of the flag (FE-STATE-06).

## Definition of done

- [ ] With the switch on, no outbound call leaves the app from any feature, and capture, editing, review and export all
  still work.
- [ ] Turning it off drains the queued work; turning it on retries nothing.
- [ ] The status line distinguishes offline by choice from offline by radio.
- [ ] Tests: an integration test with a recording HTTP boundary asserting zero outbound calls with the switch on and
  drain on release, and a widget test asserting the switch is the only writer of the flag.

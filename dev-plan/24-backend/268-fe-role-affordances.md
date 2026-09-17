# 268 — App: role affordances, cached grants and offline authority

**Phase** 24 · The minimal backend  |  **Depends on** [256](256-be-permissions.md), [267](267-fe-backend-config.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The one service that answers "what may this device do right now", and the gate that reads it: the role matrix mirrored
once as data, session and grant caches that survive a restart, and an answer that never waits on the network. §70.4 is
the contract — a device that has signed in once behaves, with the server unreachable, exactly as if no server existed.

## Files

- `frontend/lib/features/account/domain/role_gate.dart` (new)
- `frontend/lib/core/backend/offline_authority.dart` (new)
- `frontend/lib/core/backend/grant_cache.dart` (new)
- `frontend/test/features/account/role_matrix_test.dart` (new)
- `frontend/test/core/backend/offline_authority_test.dart` (new)

## Contract

```dart
enum AuthorityState { fresh, cachedValid, cachedExpired, neverSignedIn }

abstract class OfflineAuthority {
  AuthorityState get state;
  DateTime? get grantsExpireAt;
  bool may(Capability capability);   // capture, review, export, relay, aiProxy, adminAction
}
```

## Steps

1. Mirror the server's role matrix (§71.3) once, as data, and read every affordance from it.
2. Cache the session and the role grant separately, each with its own configurable lifetime (default 30 days), and
   persist both so they survive a restart.
3. Answer `may()` from the cache, never from the network. Capture, review, editing, validation, export and manual bundle
   exchange are permitted in every state except `neverSignedIn`.
4. Past expiry, keep full read, capture, review, edit and export access to the projects the device already holds, and
   withhold only the three things that genuinely need the server: relay, the AI proxy, and a changed role grant.
5. Hide what a role cannot do rather than disabling a control whose absence would puzzle a user without explanation.
6. Refresh both caches opportunistically whenever the server is reachable, never on a schedule that interrupts work.
7. Surface the state in the status line (§56 rule 13) as a quiet indicator, and give **More** one line saying when the
   grant expires.

## Constraints

- The connectivity signal, secure store and settings store already exist; this task adds no second copy of any of them
  (FE-CONS-01, FE-STR-09).
- `role_gate.dart` is pure Dart under `domain/`: no HTTP client, no Drift, no Flutter import (FE-STR-05).
- The matrix and the grant are each one source of truth; two providers must not be able to disagree about a capability
  (FE-STATE-06).

## Definition of done

- [ ] The interface never offers an action the server will refuse, and the role matrix exists in exactly one place.
- [ ] A device 45 days offline, past both cache lifetimes, still captures, reviews, edits and exports the projects it
      holds, and refuses only relay, the AI proxy and a role change, saying which in plain language.
- [ ] No code path anywhere in the app blocks capture on an authority check.
- [ ] Tests: a table test per role over the capability list, compared against the server's matrix; unit tests over all
      four authority states and every capability; a clock-advance test proving expiry never disables capture or export.

## Out of scope

- Sign-in and enrolment mechanics; that is 497.

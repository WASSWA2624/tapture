# 267 — App: backend connection, sign in and enrolment

**Phase** 24 · The minimal backend  |  **Depends on** [027](../02-foundation/027-secure-storage-service.md), [044](../03-design-system/044-app-form-scaffold.md), [079](../07-account-and-settings/079-settings-shell.md), [255](255-be-auth-tokens.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The client side of a backend every deployment has: the organisation's server address, the enrolment state machine, the
one sign-in the app ever asks for, and the settings screen that shows all of it. There is no switch that turns the
backend off (§70) — a connection is enrolled, enrolling, revoked or not yet enrolled.

## Files

- `frontend/lib/core/backend/backend_config.dart` (new)
- `frontend/lib/core/backend/backend_api_client.dart` (new)
- `frontend/lib/features/account/presentation/sign_in_screen.dart` (new)
- `frontend/lib/features/account/presentation/backend_settings_screen.dart` (new)
- `frontend/test/core/backend/enrolment_state_test.dart` (new)
- `frontend/test/features/account/sign_in_test.dart` (new)

## Contract

```dart
enum EnrolmentState { notEnrolled, enrolling, enrolled, revoked }

class BackendConfig {
  Uri get baseUrl;
  String? get organisationId;
  EnrolmentState get state;
}
```

## Steps

1. Read the server address from build configuration, and let an administrator set it once at first run for a self-hosted
   deployment; store it with the enrolment state, never in the database.
2. Put every authentication and enrolment call in `backend_api_client.dart`; the screens call the client and never a
   server.
3. Gate first run on sign-in, and only first run. Once enrolled, the app opens straight into work for the whole cached
   period, refreshing tokens silently whenever the server happens to be reachable.
4. Reconcile the local operator profile at enrolment: the account identity becomes the attribution identity, and records
   already captured under the local profile keep their attribution and gain the account identifier (§71.2).
5. Handle sign-out as an explicit, confirmed action warning that signing back in needs connectivity.
6. Show in Settings the server address, the signed-in account, the enrolment state and when the cached grant expires.
   Nothing on that screen toggles whether the backend exists, and unreachable is one quiet status line rather than an
   error banner.

## Constraints

- Tokens, the organisation identifier and any key go to platform secure storage and nowhere else — never the database,
  logs, exports, bundles or preferences (FE-SEC-01).
- The HTTP import lives in `core/backend/` only; no screen speaks to a server (FE-SEC-03, FE-STR-11).
- Signing in once is the only thing a new install asks for: no onboarding tour, no wizard, no second login (FE-SIMP-04).

## Definition of done

- [ ] A signed-in device works for the full cached period with no connectivity and never shows a sign-in screen again.
- [ ] An unreachable server changes nothing about what the app will let a user do, and says so in one quiet line.
- [ ] No token, key or organisation identifier is written anywhere but secure storage.
- [ ] Records captured before enrolment keep their operator attribution and gain the account identity.
- [ ] Tests: unit tests over the enrolment state machine and over sign-in, silent refresh, expiry and offline fallback; a
      test asserting no credential reaches the database, a log or an export; a test for operator-profile reconciliation.

## Out of scope

- Deciding what a role may do, and what a device may do past grant expiry; that is 499.

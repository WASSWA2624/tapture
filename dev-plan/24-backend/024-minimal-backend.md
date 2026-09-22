# 024 — The minimal backend, and the app that runs on it

**Phase** 24 · The minimal backend  |  **Depends on** [002](../02-foundation/002-foundation-services.md), [003](../03-design-system/003-design-system.md), [007](../07-account-and-settings/007-account-and-settings.md), [013](../13-processing/013-processing.md), [019](../19-bundles-and-merge/019-bundles-and-merge.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The required minimal backend of specification Part XI, and the client work that makes the app run on it. A Node and
TypeScript project in `backend/` with strict compiler settings, the fixed eight-directory module tree and one `verify`
command that reproduces the whole gate; typed configuration validated once at boot; a JSON logger with an
unbypassable redaction list, the sealed error type every layer throws and the one documented envelope every failure
renders as; and an Express application with a fixed middleware order, a request identifier threaded across every async
boundary, configured body and rate limits, and liveness, readiness and version routes. Beneath it a Postgres pool with
timeouts and a graceful drain, a numbered forward-only migration runner proven from the previously released schema,
four migrations — organisations, users and devices; projects and memberships; relay packages, acknowledgements and
version vectors; append-only audit and security events — and the repository base whose transaction helper makes a
multi-table write atomic or nothing. On that sits identity: Argon2id storage with administrator-created accounts,
invitation acceptance, password change and reset; sign-in with per-address and per-account limits and lockout;
short-lived access tokens with rotating device-bound refresh tokens, the authentication middleware, sign-out, and
device enrolment, listing and revocation; and one pure permission function over administrator, project manager,
reviewer and field operator with the table-driven matrix test behind it. Over that the organisation user endpoints,
`GET /auth/me` — the identity and grants a device caches to keep working with the server unreachable — and project
registration and membership management over identifiers and settings only. One slice is optional: the change relay,
which adds a size-limited idempotent upload of an opaque blob, the unacknowledged list and the download,
acknowledgement with immediate delete once the set is complete, the version-vector state endpoint, and the scheduled
purge with per-project and per-organisation storage ceilings. Beside it AI custody: one provider interface with a fake
that can fail, time out and return malformed output, a key holder no caller can read back, the four pass-through proxy
endpoints with server-side quotas, the usage report, and bounded, retrying, circuit-broken calls. Then the audit
service every privileged action writes through, the metrics route, the OpenAPI document with its contract suite and
drift fixture, the export and destroy commands, and the image, compose file, runbook and pipeline that run and leave
this server. On the app side: the organisation's server address, the enrolment state machine, the one sign-in the app
ever asks for and the settings screen showing all of it; a role gate and an offline authority answering from caches
that survive a restart and never wait on the network; the relay client and its per-project controls, built on the
existing bundle and merge machinery; and the proxy implementation of `AiService`, registered as the default provider
so a fresh install extracts with no key ever entered on the device.

## Files

### Backend — project, gate and configuration

- `backend/package.json` (new)
- `backend/tsconfig.json` (new)
- `backend/.eslintrc.cjs` (new)
- `backend/.prettierrc` (new)
- `backend/src/{routes,services,repositories,domain,middleware,jobs,config,types}/index.ts` (new)
- `backend/scripts/verify.ts` (new)
- `backend/src/config/index.ts` (new)
- `backend/src/config/schema.ts` (new)
- `backend/test/boot.test.ts` (new)
- `backend/test/tools/verify.test.ts` (new)
- `backend/test/config/config.test.ts` (new)

### Backend — observability, errors and the HTTP server

- `backend/src/observability/logger.ts` (new)
- `backend/src/domain/errors.ts` (new)
- `backend/src/middleware/error_handler.ts` (new)
- `backend/src/server.ts` (new)
- `backend/src/routes/health.ts` (new)
- `backend/src/middleware/request_context.ts` (new)
- `backend/src/middleware/rate_limit.ts` (new)
- `backend/test/observability/log_leak.test.ts` (new)
- `backend/test/middleware/error_handler.test.ts` (new)
- `backend/test/routes/health.test.ts` (new)
- `backend/test/middleware/request_context.test.ts` (new)
- `backend/test/middleware/rate_limit.test.ts` (new)

### Backend — database, schema and repositories

- `backend/src/db/pool.ts` (new)
- `backend/src/db/migrate.ts` (new)
- `backend/migrations/` (new)
- `backend/migrations/001_identity.sql` (new)
- `backend/migrations/002_projects.sql` (new)
- `backend/migrations/003_relay.sql` (new)
- `backend/migrations/004_audit.sql` (new)
- `backend/src/repositories/base.ts` (new)
- `backend/test/db/pool.test.ts` (new)
- `backend/test/db/migrate.test.ts` (new)
- `backend/test/repositories/identity.test.ts` (new)
- `backend/test/repositories/membership.test.ts` (new)
- `backend/test/repositories/relay_schema.test.ts` (new)
- `backend/test/repositories/audit_schema.test.ts` (new)
- `backend/test/repositories/transaction.test.ts` (new)

### Backend — authentication, sessions and roles

- `backend/src/services/auth/password.ts` (new — hashing, change and reset)
- `backend/src/services/auth/register.ts` (new)
- `backend/src/services/auth/login.ts` (new)
- `backend/src/services/auth/tokens.ts` (new)
- `backend/src/routes/auth/register.ts` (new)
- `backend/src/routes/auth/password.ts` (new)
- `backend/src/routes/auth/login.ts` (new)
- `backend/src/routes/auth/session.ts` (new)
- `backend/src/routes/devices.ts` (new)
- `backend/src/middleware/authenticate.ts` (new)
- `backend/src/domain/permissions.ts` (new)
- `backend/test/services/password.test.ts` (new)
- `backend/test/services/tokens.test.ts` (new)
- `backend/test/routes/auth_account.test.ts` (new)
- `backend/test/routes/auth_login.test.ts` (new)
- `backend/test/routes/devices.test.ts` (new)
- `backend/test/middleware/authenticate.test.ts` (new)
- `backend/test/domain/permission_matrix.test.ts` (new)

### Backend — organisation, project and membership endpoints

- `backend/src/routes/org/users.ts` (new)
- `backend/src/routes/auth/me.ts` (new)
- `backend/src/routes/projects.ts` (new)
- `backend/src/services/users.ts` (new)
- `backend/src/services/projects.ts` (new)
- `backend/test/routes/org_users.test.ts` (new)
- `backend/test/routes/auth_me.test.ts` (new)
- `backend/test/routes/projects.test.ts` (new)
- `backend/test/routes/members.test.ts` (new)

### Backend — the optional change relay

- `backend/src/routes/relay/push.ts` (new)
- `backend/src/routes/relay/fetch.ts` (new)
- `backend/src/routes/relay/ack.ts` (new)
- `backend/src/routes/relay/state.ts` (new)
- `backend/src/services/relay/packages.ts` (new)
- `backend/src/services/relay/purge_decision.ts` (new)
- `backend/src/services/relay/quota.ts` (new)
- `backend/src/repositories/relay.ts` (new)
- `backend/src/domain/version_vector.ts` (new)
- `backend/src/domain/retention.ts` (new)
- `backend/src/jobs/purge.ts` (new)
- `backend/test/routes/relay_push.test.ts` (new)
- `backend/test/routes/relay_fetch.test.ts` (new)
- `backend/test/routes/relay_state.test.ts` (new)
- `backend/test/services/purge_decision.test.ts` (new)
- `backend/test/services/storage_quota.test.ts` (new)
- `backend/test/jobs/purge.test.ts` (new)

### Backend — AI custody and the proxy

- `backend/src/services/ai/provider.ts` (new)
- `backend/src/services/ai/keys.ts` (new)
- `backend/src/services/ai/quota.ts` (new)
- `backend/src/services/ai/resilience.ts` (new)
- `backend/src/routes/ai.ts` (new)
- `backend/test/fakes/fake_provider.ts` (new)
- `backend/test/services/provider_contract.test.ts` (new)
- `backend/test/services/key_custody.test.ts` (new)
- `backend/test/services/ai_quota.test.ts` (new)
- `backend/test/services/ai_resilience.test.ts` (new)
- `backend/test/routes/ai_proxy.test.ts` (new)

### Backend — audit, metrics and the API contract

- `backend/src/services/audit.ts` (new)
- `backend/src/routes/metrics.ts` (new)
- `backend/openapi.yaml` (new)
- `backend/test/services/audit.test.ts` (new)
- `backend/test/routes/metrics.test.ts` (new)
- `backend/test/contract/` (new)
- `backend/test/contract/fixtures/drifted_route.ts` (new)

### Backend — administration, deployment and the pipeline

- `backend/src/cli/admin.ts` (new)
- `backend/Dockerfile` (new)
- `backend/docker-compose.yml` (new)
- `backend/RUNBOOK.md` (new)
- `.github/workflows/backend.yml` (new)
- `backend/test/cli/admin.test.ts` (new)
- `backend/test/deploy/image_smoke.test.ts` (new)

### App — connection, sign-in and enrolment

- `frontend/lib/core/backend/backend_config.dart` (new)
- `frontend/lib/core/backend/backend_api_client.dart` (new)
- `frontend/lib/features/account/presentation/sign_in_screen.dart` (new)
- `frontend/lib/features/account/presentation/backend_settings_screen.dart` (new)
- `frontend/test/core/backend/enrolment_state_test.dart` (new)
- `frontend/test/features/account/sign_in_test.dart` (new)

### App — role affordances and offline authority

- `frontend/lib/features/account/domain/role_gate.dart` (new)
- `frontend/lib/core/backend/offline_authority.dart` (new)
- `frontend/lib/core/backend/grant_cache.dart` (new)
- `frontend/test/features/account/role_matrix_test.dart` (new)
- `frontend/test/core/backend/offline_authority_test.dart` (new)

### App — the relay client and the AI proxy client

- `frontend/lib/core/backend/relay_client.dart` (new)
- `frontend/lib/features/account/presentation/relay_settings_screen.dart` (new)
- `frontend/lib/core/ai/proxy_ai_service.dart` (new)
- `frontend/lib/core/ai/provider_registry.dart` (changed)
- `frontend/test/core/backend/relay_round_trip_test.dart` (new)
- `frontend/test/features/account/relay_settings_test.dart` (new)
- `frontend/test/core/ai/proxy_ai_service_test.dart` (new)

## Contract

```text
npm run dev | npm run build | npm run test | npm run verify
npm run admin -- export --out <dir> | npm run admin -- destroy --confirm <org>
```

```ts
export const config: AppConfig; // throws at import time on an invalid environment

log.info(event: string, fields: Record<string, unknown>): void

class AppError extends Error { code: ErrorCode; status: number; publicMessage: string; details?: object }

export const ctx: AsyncLocalStorage<RequestContext>;

withTransaction<T>(fn: (tx: Tx) => Promise<T>): Promise<T>

hashPassword(plain: string): Promise<string>;  verifyPassword(plain: string, hash: string): Promise<boolean>
issueTokens(userId, deviceId): Promise<TokenPair>;  rotate(refresh: string): Promise<TokenPair>
revoke(refresh: string): Promise<void>

can(principal: Principal, capability: Capability, scope?: Scope): boolean

interface AiProvider { extract(req): Promise<Res>; ocr(req): Promise<Res>; transcribe(req): Promise<Res>; refine(req): Promise<Res> }

runPurge(now: Date): Promise<PurgeReport>   // { deleted, bytesReclaimed, oldestAgeSeconds, failures }

recordAudit(actor: Principal, action: AuditAction, target: AuditTarget, outcome: Outcome): Promise<void>
```

```text
GET  /health    GET /ready    GET /version    GET /metrics

POST /api/v1/auth/register        POST /api/v1/auth/change-password   POST /api/v1/auth/reset
POST /api/v1/auth/login           // { email, password, deviceId } -> TokenPair
POST /api/v1/auth/refresh         POST /api/v1/auth/logout
GET  /api/v1/auth/me

POST /api/v1/devices              GET  /api/v1/devices                DELETE /api/v1/devices/:id

GET  /api/v1/org/users            POST /api/v1/org/users              PATCH  /api/v1/org/users/:id

POST /api/v1/projects             GET  /api/v1/projects               PATCH  /api/v1/projects/:id
GET  /api/v1/projects/:id/members
POST /api/v1/projects/:id/members
DELETE /api/v1/projects/:id/members/:userId

POST /api/v1/projects/:id/relay/packages              // Idempotency-Key header
GET  /api/v1/projects/:id/relay/packages              // limit, cursor -> unacknowledged for this device
GET  /api/v1/projects/:id/relay/packages/:packageId   // ciphertext bytes
POST /api/v1/relay/ack                                // { packageIds[] }, Idempotency-Key header
GET  /api/v1/projects/:id/relay/state                 // vectors per device, queue depth for this device

POST /api/v1/ai/extract   POST /api/v1/ai/ocr   POST /api/v1/ai/transcribe   POST /api/v1/ai/refine
GET  /api/v1/ai/usage?project=&from=&to=
```

```dart
enum EnrolmentState { notEnrolled, enrolling, enrolled, revoked }

class BackendConfig {
  Uri get baseUrl;
  String? get organisationId;
  EnrolmentState get state;
}

enum AuthorityState { fresh, cachedValid, cachedExpired, neverSignedIn }

abstract class OfflineAuthority {
  AuthorityState get state;
  DateTime? get grantsExpireAt;
  bool may(Capability capability);   // capture, review, export, relay, aiProxy, adminAction
}
```

## Steps

### The server skeleton

1. Initialise the project and its gate. Enable `strict`, `noImplicitAny`, `noUncheckedIndexedAccess` and
   `exactOptionalPropertyTypes`; warnings are errors in continuous integration. Create the eight source directories of
   BE-STR-02, each with an index. Configure lint rules that ban `any`, non-null assertions, floating promises,
   `console` statements and circular imports. `scripts/verify.ts` runs format, lint, type check, unit, integration and
   contract stages plus the dependency advisory and secret scans, prints one summary table and exits non-zero when any
   stage fails.
2. Add the typed configuration module. Declare every variable with its type, default, whether it is required and a
   one-line description: listener, database URL and pool sizes, token lifetimes, body and package size limits, rate
   limits, retention window, storage ceilings, AI budgets and provider selection, log level. Export typed values only,
   and add the lint rule that forbids `process.env` anywhere outside this module.
3. Build the logger, the sealed error type and the error envelope. Emit one JSON line per event with timestamp, level,
   request identifier, route, user, device and outcome. Redact before serialisation, not at the call site: provider
   keys, tokens, passwords, package bytes, captions, transcripts, field values, user-supplied file names and whole
   request bodies. Give every `ErrorCode` a status from the BE-API-04 set, render
   `{ error: { code, message, details } }` and nothing else, and log the cause once, internally, with the request
   identifier; the response carries only `publicMessage`, never an internal message, a stack or a database error
   string. This `AppError` is the typed error every later step in this file throws.
4. Build the Express application. Fix the chain order: request context, body limits, security headers, rate limiter,
   authentication, router, error handler. Generate a request identifier at the edge, carry it through `ctx` across
   every async boundary, attach it to every log line and return it to the client. `/health` reports process liveness
   only; `/ready` additionally checks the database pool and the secret store; `/version` returns the build and API
   version. Apply a global limit plus stricter per-endpoint limits on authentication and relay upload, keyed by address
   and by account, with maximum body and package sizes taken from configuration.

### Schema and repositories

5. Open the Postgres pool and the migration runner. Size the pool and its connection and statement timeouts from
   configuration, and expose a status the readiness route can read. Drain on shutdown: stop handing out connections,
   let in-flight transactions finish, close the pool, exit. Apply migrations in filename order, each inside a
   transaction, recording every applied file in a schema history table; refuse to run out of order or to re-run a
   changed file. Expose migration as an explicit command or job behind a flag, never as an implicit step of every boot.
6. Write the identity and project migrations. `organisations`; `users` with email, password hash, role, organisation
   and status; `devices` with the device identifier, user, enrolled time, last seen and revoked state. Unique email per
   organisation and unique device identifier, both by constraint. `projects` stores the identifier the device
   generated, name, organisation and relay settings — and no column that could hold a record, a photo, a template or
   any other content. `project_members` joins a user to a project with a role and an optional context scope, unique per
   pair.
7. Write the relay and audit migrations. `relay_packages` carries identifier, project, author device, byte size,
   created, expires and storage reference, and nothing else — no content column, no field drawn from a project.
   `relay_acknowledgements` records device, package and time, unique per pair; `relay_vectors` records project, device
   and counter, one row per project and device rather than per package. `audit_events` and `security_events` record
   actor, target, action, outcome and time, with update and delete forbidden by constraint or trigger.
8. Establish the repository conventions and the transaction helper, so a failure part-way through a multi-table write
   leaves no partial rows. Parameterised statements only, taking the connection or the ambient transaction, never
   opening a second one. Map database errors — unique violation, foreign key violation, serialisation failure — onto
   the sealed `AppError` of step 3, so no driver message can reach a client.

### Authentication and roles

9. Store passwords with Argon2id and build the four account endpoints §71.1 names other than sign-in. §74.2 is the
   whole API (BE-API-01), so these are built here rather than left implied. Document the parameters beside the code and
   read them from configuration, so raising them later is a value change; verification tolerates a hash written with
   older parameters and rehashes on next successful use. An administrator creates an account; the invitee accepts by
   setting a password against a single-use invitation token, and self-service registration stays disabled unless the
   organisation enables it. Change-password requires the current password, re-hashes, and invalidates every
   refresh-token family for that user so an old session cannot outlive the change. Reset issues a single-use,
   short-lived, rate-limited token and answers identically whether or not the address is known, so the endpoint is not
   an account oracle (BE-SEC-07, BE-API-09). Each of these writes an administrative audit entry (BE-OBS-07).
10. Build sign-in. Answer a wrong password and an unknown address identically, in the same time envelope, with the same
    code. Count failures per address and per account against the thresholds in configuration; on lockout, refuse until
    the window elapses or an administrator clears it, and say so without naming which condition applied. Clear the
    failure count on a successful sign-in, and record a security event for each failure and for the lockout itself.
11. Build the session mechanics and device enrolment, which is what makes server-side roles meaningful. Bind every
    refresh token to a device identifier and a family; rotation issues the next token and retires the previous one.
    Detect refresh reuse, invalidate the whole family and log a security event. Sign-out revokes the presenting
    device's family and is idempotent: signing out twice, or with an already-expired token, succeeds silently rather
    than erroring (BE-API-07); it is a server-side revocation only and never reaches the device's project data, which
    stays exactly where it is (§70.2). The middleware verifies the access token, loads the principal with its
    organisation, role and enrolled device, and attaches it to the request context; expired, malformed and missing
    tokens all give 401 in the standard envelope. Enrolment records the device identifier, model, application version
    and enrolment time against the account; an administrator may list and revoke devices, and a revoked device can
    neither refresh nor reach the relay.
12. Implement the role matrix as one permission function over administrator, project manager, reviewer and field
    operator, including a membership's optional context scope narrowing a project-level grant. Call `can` from
    services, so a new route cannot forget the check. Where a capability is refused because the caller cannot see the
    resource at all, the service raises the not-found error, not the forbidden one.

### The organisation and project APIs

13. Build the organisation user endpoints and the one directory endpoint that is not administrator-only. `PATCH`
    covers role change and status change only; a password never travels through this surface, and a role change writes
    an audit entry naming actor, target, old role and new role. `GET /auth/me` returns the account identity,
    organisation, role, project grants and the grant validity window the device needs in order to cache them — the
    thing that keeps a device working with the server unreachable (§70.4, §71.2).
14. Build project registration and membership management, over identifiers and settings only: the device announces a
    project it already owns, and the server records who may see it and whether relay is enabled for it. Accept the
    client-generated project identifier on registration; reject any request that would change it, and never generate a
    replacement. `PATCH` covers name and relay settings — enabled, retention window within the permitted maximum, and
    the never-relay marking — and only a project manager or administrator may change them. Membership changes are
    transactional and write an audit entry; a relay enablement change writes one too.

### The optional change relay

15. Build the three transit endpoints. Store the blob without parsing it and record only the metadata BE-RELAY-06
    permits; set `expires_at` from the project's retention window at insert time. Refuse a project marked never-relay,
    or one with relay disabled, in the service — not merely in the client (BE-RELAY-09). Replaying an idempotency key
    returns the original result and creates nothing; a package over the configured size limit gives 413. List and
    download only for an enrolled, unrevoked device of a member of that project, and log every access with package
    identifier, project, device and outcome.
16. Build acknowledgement, the delete decision that runs in the same transaction as it, and the version-vector
    endpoint. Record the acknowledgement, recompute completeness against the currently enrolled, unrevoked devices of
    the project, and delete the package and its rows in the same transaction when the set is complete. Replaying an
    acknowledgement changes nothing and still returns success, including when the package has already been purged.
    Advance the caller's version-vector counter as part of the same transaction, and return the vectors and queue depth
    from `state`. Compare vectors in `domain/version_vector.ts` as pure functions, so the ordering logic is
    unit-testable without a database.
17. Build the purge job and the storage ceilings, so unchecked growth becomes a clear error instead of a full disk.
    Delete every package past its expiry in bounded batches, each batch a transaction, whether acknowledged or not.
    Compute the retention window in `domain/retention.ts` and clamp it to the hard maximum of 90 days in code, not by
    policy; a configured value above it is a boot failure. Record counts, ages and bytes reclaimed on every run, expose
    them as metrics, and make the last report readable by an administrator. Check the project and organisation ceilings
    before accepting an upload, returning a typed error naming the ceiling reached and what to do about it.

### AI custody and the proxy

18. Build the provider interface, its fake and the key holder. Select the implementation by one configuration value, so
    adding a provider adds a file and a value and touches no route. The fake can succeed, fail, time out and return
    malformed output, so every failure path has a way to be tested (BE-TEST-06). Read keys from the secret store at
    boot and hold them behind an accessor that returns a configured client, never the key itself; a key never appears
    in a response, a log line, an error message or an exported report.
19. Build the proxy endpoints, the budgets and the bounded call behaviour. Forward what the device composed and return
    what the provider answered: no prompt rewriting, no injected instruction, no reinterpretation of a result, no
    silent model downgrade. Stream or buffer within the configured size limit and persist nothing — not to disk, not
    to the database, not to a cache — beyond the life of the request. Check the per-project and per-organisation
    budget, request count and daily cap before the provider call; record project, user, model, byte size, duration,
    outcome and cost after it, and serve `usage` from those rows. Bound every call with a timeout, retry transient
    failures with backoff, and open a circuit breaker on sustained failure so the caller gets a typed, queueable error
    within the timeout.

### Audit and the API contract

20. Build the audit service every privileged action calls, and the metrics route. Cover user creation, role change, key
    rotation, retention change, relay enablement, device revocation and purge runs, writing one row each with actor,
    target, action, outcome and time, in the same transaction as the action it describes, so neither can exist without
    the other. Expose request rate, latency and error rate per route; packages stored, acknowledged and purged; storage
    bytes by project; AI requests and cost; authentication failures.
21. Write the OpenAPI document and the contract suite that keeps it honest. Describe every endpoint of §74.2: request
    and response schemas, every error code, every status, the pagination parameters and the configured limits. Drive
    each documented operation against a booted server with a migrated database, asserting status, envelope and schema
    for both the success and the documented failure cases. Ship the drift fixture: a route whose shape no longer
    matches the document, proving the suite fails on it.

### Shipping the server

22. Build everything needed to run and to leave this server. Export accounts, devices, memberships, roles, audit rows
    and package metadata as files an operator can read, stating in the output that projects are not included because
    the server never held them. Destroy requires the organisation named explicitly plus a second confirmation, and
    reports what it deleted. One image, one process, non-root user, twelve-factor configuration, no baked configuration
    file; migrations run as an explicit step; shutdown stops accepting connections, finishes in-flight requests, closes
    the pool and exits. The runbook covers deploy, upgrade, rotate a key, change retention, investigate a failed purge,
    and restore — and states that a server backup holds accounts, roles and metadata, never projects. The workflow
    runs `npm run verify` on every push against an ephemeral Postgres, and nothing else: it reproduces the gate rather
    than re-implementing it (BE-FLOW-02).

### The app side

23. Build the client side of a backend every deployment has. There is no switch that turns the backend off (§70) — a
    connection is enrolled, enrolling, revoked or not yet enrolled. Read the server address from build configuration,
    and let an administrator set it once at first run for a self-hosted deployment; store it with the enrolment state,
    never in the database. Put every authentication and enrolment call in `backend_api_client.dart`; the screens call
    the client and never a server. Gate first run on sign-in, and only first run: once enrolled, the app opens straight
    into work for the whole cached period, refreshing tokens silently whenever the server happens to be reachable.
    Reconcile the local operator profile at enrolment, so the account identity becomes the attribution identity and
    records already captured under the local profile keep their attribution and gain the account identifier (§71.2).
    Handle sign-out as an explicit, confirmed action warning that signing back in needs connectivity. Show in Settings
    the server address, the signed-in account, the enrolment state and when the cached grant expires; nothing on that
    screen toggles whether the backend exists, and unreachable is one quiet status line rather than an error banner.
24. Build the one service that answers what this device may do right now, and the gate that reads it. Mirror the
    server's role matrix (§71.3) once, as data, and read every affordance from it. Cache the session and the role grant
    separately, each with its own configurable lifetime, default 30 days, and persist both so they survive a restart.
    Answer `may()` from the cache, never from the network: capture, review, editing, validation, export and manual
    bundle exchange are permitted in every state except `neverSignedIn`. Past expiry, keep full read, capture, review,
    edit and export access to the projects the device already holds, and withhold only the three things that genuinely
    need the server — relay, the AI proxy, and a changed role grant. Hide what a role cannot do rather than disabling
    a control whose absence would puzzle a user without explanation. Refresh both caches opportunistically whenever the
    server is reachable, never on a schedule that interrupts work. Surface the state in the status line (§56 rule 13)
    as a quiet indicator, and give **More** one line saying when the grant expires.
25. Build the relay client and its controls on the existing bundle and merge machinery. Build a delta bundle since the
    last acknowledged version with the existing writer, encrypt it with the project key, and push it with an
    idempotency key so a dropped connection cannot duplicate it. Pull the packages this device has not acknowledged,
    decrypt them, and hand them to the existing merge preview and conflict flow untouched; acknowledge only after a
    merge has been applied. Offer per-project enable, a schedule, Wi-Fi only, and a never-relay marking; relay stays
    off until a project manager turns it on. Show queued, sent and purged packages, so what has left the device is
    always visible.
26. Route AI through the backend and make that the default custody arrangement. Implement the existing `AiService`
    interface against the proxy endpoints, queueing on failure exactly as the direct provider does, and register it in
    `provider_registry.dart` as the default provider for every project, so a fresh install holds no key and needs none
    (§30.2, §73.1). Keep the device-held key path as the administrator-permitted exception it now is: selectable per
    project and labelled as the lone-operator arrangement. Surface the server's quota, budget and usage figures (§36)
    in the same counters the direct path already uses.

## Constraints

- The backend is required to exist and never required to be reachable. It holds people, permissions and keys; it is
  never the store of record, never a backup, and never in the way of a field worker (§70, §70.4).
- The change relay is the backend's one **optional** capability (§72): the relay and audit migration's relay tables,
  the three transit endpoints, acknowledgement and state, the purge job with its storage ceilings, and the app's relay
  client and controls. An organisation that never enables it must still have a complete, fully working product.
- The module tree is exactly the one in BE-STR-02; no ninth directory, no file above roughly 300 lines (BE-STR-09). One
  command reproduces the gate and behaves identically locally and in continuous integration (BE-FLOW-02).
- Every timeout, limit, retention window and page size used elsewhere originates in `config/` with a documented default
  (BE-CODE-09, BE-DEP-02). Boot fails loudly rather than starting half-configured (BE-DEP-03), and no secret is ever
  read from source or the database (BE-SEC-04).
- The redaction list is BE-OBS-02 in full, and a field passed deliberately must not escape it. `debug` is off in
  production; `error` means actionable (BE-OBS-04).
- Errors are a sealed type with a code and a public message; never a bare string, never a leaked internal (BE-CODE-05),
  and every code maps to a status in the BE-API-04 set.
- Limits are enforced by middleware, never by a route handler (BE-API-08); exceeding one returns 429 with a retry hint
  and a logged security event (BE-SEC-07). No plaintext listener; HSTS on (BE-SEC-01). Readiness is separate from
  liveness so a deployment takes no traffic before it can serve it (BE-OBS-06).
- Migrations are forward-only and never edited after release; a destructive one needs the runbook export step and an
  explicit approval (BE-DATA-04, BE-DATA-05). The database user cannot create schemas (BE-SEC-09).
- Client identifiers are authoritative: the server never reassigns a project identifier and never invents one
  (BE-DATA-02). Registration stores no record, photo, template or field value; the server holds metadata only
  (BE-DATA-03).
- Foreign keys, uniqueness and not-null are declared in the database, not only checked in code (BE-DATA-07); every
  index carries a comment naming the query it serves (BE-DATA-08); all timestamps are `timestamptz` (BE-DATA-10).
- Every transient table carries `created_at`, `expires_at` and acknowledgement state so purge needs no special case
  (BE-DATA-06). The package metadata list is closed by BE-RELAY-06, and version vectors carry counters and device
  identifiers only, never a record identifier or a field name.
- SQL exists nowhere outside `repositories/`, and services depend on repository interfaces so they can be tested
  without a database (BE-STR-04, BE-TEST-02). Relay acknowledgement, membership change and purge batches are atomic or
  they do not happen (BE-DATA-09).
- A memory-hard hash only; never a fast hash, never a reversible scheme, and never a hash in a log or a response
  (BE-SEC-02). Email uniqueness per organisation is enforced without revealing whether an address exists, and the
  submitted password never reaches a log line or an audit row (BE-OBS-02).
- Lockout and its security event are required, not advisory (BE-SEC-07); the per-address ceiling comes from the
  middleware limiter already in the chain and is not re-implemented in the login service.
- Access tokens are short-lived; refresh tokens rotate and are device-bound; reuse invalidates the family and is logged
  as a security event (BE-SEC-03).
- Membership is not an oracle — invisible and forbidden look identical to the caller (BE-API-09). Authorisation is
  decided in the service through `can`, never in the route (BE-SEC-06), and extending the capability list extends the
  matrix test in the same change (BE-TEST-04).
- `domain/` stays pure: no HTTP, no database client, no framework import (BE-STR-05).
- Listing is cursor-paginated with `limit`, `cursor` and `nextCursor`; no endpoint here returns an unbounded list
  (BE-API-06).
- The server has no code path that decrypts, unpacks, parses or inspects a package (BE-RELAY-02, BE-SEC-08), and it
  never merges, resolves or orders changes (BE-RELAY-11). A non-member, or a device of a non-member, gets 404 for a
  package that exists (BE-API-09), and a never-relay or relay-disabled project is refused in the service (BE-RELAY-09).
- Purge on acknowledgement is immediate and recorded in the same transaction as the delete decision (BE-RELAY-03,
  BE-DATA-09). No archive, no cold copy, no analytics extract of a package on the way out (BE-RELAY-05); a device that
  misses the window re-synchronises from a peer. Purge is provable: the clock is injected so a test can advance it
  (BE-RELAY-08, BE-TEST-05).
- Provider keys live only in the key holder, and that custody is the reason the proxy exists (BE-AI-01, BE-SEC-04).
  Providers sit behind one interface so a swap is one implementation and one configuration change (BE-AI-06).
- Payloads are never persisted and logs carry metadata only — never a caption, transcript, field value or image
  (BE-AI-02, BE-AI-03). Quotas are enforced on the server because there they cannot be bypassed by an edited client
  (BE-AI-05). The proxy never fabricates a result and is never assumed to be the only path; an unreachable proxy is the
  client's queue, not an error to swallow (BE-AI-08, BE-AI-10).
- Audit rows are append-only; the service exposes no update or delete path (BE-OBS-07). Metrics name the boundary
  failures worth alerting on — storage growing while purge stays flat, purge failing, authentication failures spiking,
  AI spend crossing a threshold (BE-OBS-09) — and no metric label carries project content, a user file name or any
  other forbidden field (BE-OBS-02).
- The OpenAPI document lives beside the code and changes in the same pull request as the route, its contract test and
  the client expectation (BE-STR-10, BE-FLOW-03). Version drift is documented behaviour: an older or newer client
  receives a clear version message rather than an obscure failure (BE-API-10).
- One container, one organisation; no multi-tenancy (BE-DEP-01). Backups cover accounts, not projects, and the runbook
  says so plainly so nobody assumes otherwise after an incident (BE-DEP-09). Sizing that grows unexpectedly means
  retention is broken; the runbook says investigate before scaling (BE-DEP-07).
- Tokens, sessions, keys, the organisation identifier and the project key go to platform secure storage and nowhere
  else — never the database, logs, exports, bundles or preferences, and the project key never travels with a package
  (FE-SEC-01, FE-SEC-11). No key is compiled in and by default no key is on the device; custody belongs to the backend
  (FE-SEC-02).
- The HTTP import lives in `core/backend/` and `core/ai/` only; no screen and no feature speaks to a server directly
  (FE-SEC-03, FE-STR-11).
- Signing in once is the only thing a new install asks for: no onboarding tour, no wizard, no second login
  (FE-SIMP-04).
- The connectivity signal, secure store, settings store, bundle writer and merge apply already exist; a second copy of
  any of them, or a second encryption, diff or merge path, is a defect (FE-CONS-01, FE-STR-09).
- `role_gate.dart` is pure Dart under `domain/`: no HTTP client, no Drift, no Flutter import (FE-STR-05). The matrix
  and the grant are each one source of truth; two providers must not be able to disagree about a capability
  (FE-STATE-06).
- A failed proxy call queues and preserves the input; it never discards a photo, caption or typed value (FE-SIMP-09).
- Tokens, key custody and enrolment are security-relevant surface: each needs a second reader (BE-SEC-11, BE-FLOW-04).

## Definition of done

### The server skeleton

- [ ] The project builds and starts, serving nothing but a health route.
- [ ] `npm run verify` exits non-zero when any single stage fails, and names which.
- [ ] Tests: `backend/test/boot.test.ts` asserts the process starts and shuts down cleanly;
      `backend/test/tools/verify.test.ts` asserts exit-code aggregation across stages.
- [ ] A missing secret stops the process at boot with a message naming the variable.
- [ ] Nothing outside `config/` can read `process.env`, and lint proves it.
- [ ] Tests: unit tests over valid, missing and malformed environments, including a value past its permitted maximum.
- [ ] No forbidden pattern reaches the output, even when passed deliberately as a log field.
- [ ] An unexpected exception returns a 500 envelope and logs the cause exactly once.
- [ ] Tests: a leak test drives representative payloads and scans the emitted lines (BE-TEST-10); unit tests over the
      envelope shape and the status mapping of every error code, asserting no internal detail appears in a response.
- [ ] A deployment receives no traffic until readiness passes, and readiness fails when the database is absent.
- [ ] Every log line for one request shares one identifier, and the client receives it.
- [ ] Exceeding any configured limit returns 429 with a retry hint and records a security event.
- [ ] Tests: route tests for liveness, readiness and version, and a test asserting context propagation across an async
      boundary.
- [ ] Tests: a rate-limit test per limited endpoint.

### Schema and repositories

- [ ] Shutdown drains the pool without dropping an in-flight transaction.
- [ ] Migrations apply in order, record themselves, and never run implicitly at boot.
- [ ] Upgrading from the last released schema preserves every row.
- [ ] Tests: integration tests against an ephemeral database migrated from scratch for pool behaviour and drain
      (BE-TEST-03), and a migration test from the previous release schema with seeded data (BE-TEST-09).
- [ ] A project row carries the client-generated identifier and there exists no column able to hold project content.
- [ ] Email is unique per organisation and the device identifier is globally unique, enforced by constraint.
- [ ] Tests: repository integration tests for user and device creation and lookup, and for membership with and without
      a context scope, including the cross-organisation isolation case.
- [ ] Every transient row carries created and expiry columns, and the purge query needs no exception for any of them.
- [ ] No column on a package, acknowledgement or vector row can hold project content.
- [ ] Tests: integration tests for package insert, acknowledgement and the expiry query, and a test proving an audit
      row cannot be updated or deleted.
- [ ] A failure mid-transaction leaves no partial rows and surfaces a typed error, not a driver message.
- [ ] Tests: an integration test with a deliberate mid-transaction failure across two tables, and a test asserting a
      unique violation maps to the expected error code.

### Authentication and roles

- [ ] A stored hash is irreversible and appears in no log, response or error path.
- [ ] Self-service registration is off unless the organisation enables it, and neither register nor reset reveals
      whether an address exists.
- [ ] A changed or reset password invalidates every existing refresh-token family for that user.
- [ ] Tests: unit tests for hashing, verification and a parameter change; route tests for success, duplicate address,
      registration disabled, wrong current password, expired reset token and replayed reset token.
- [ ] Repeated failures lock the account and record a security event naming actor, address and time.
- [ ] A wrong password and an unknown address are indistinguishable to the caller.
- [ ] Tests: route tests for success, wrong password, unknown address, lockout, refusal while locked and the reset of
      the counter after success.
- [ ] A stolen refresh token cannot be replayed after rotation; reuse kills the family and records a security event.
- [ ] Signing out twice succeeds both times and revokes exactly one family.
- [ ] A revoked device can neither refresh a token nor reach the relay.
- [ ] Tests: unit tests for rotation, expiry, reuse detection and repeated sign-out; middleware tests for valid,
      expired, malformed and missing access tokens; route tests for enrol, list and revoke.
- [ ] A user who cannot see a project receives 404, not 403.
- [ ] Every capability is decided in one place, and no route contains a role comparison.
- [ ] Tests: the full role-by-capability matrix as a table test, including the context-scoped cases.

### The organisation and project APIs

- [ ] `GET /auth/me` returns the identity and grants the device caches, and never a credential or a provider key.
- [ ] A non-administrator cannot list or modify organisation users, and learns nothing from the attempt.
- [ ] Tests: route tests for each user endpoint across every role, including the unauthorised paths and cursor
      pagination over a page boundary.
- [ ] Registering or updating a project stores no record, photo or template content.
- [ ] An attempt to change a project identifier is refused, and the stored identifier is still the device's.
- [ ] Relay settings change only for a project manager or administrator, and the change is audited.
- [ ] Tests: route tests for registration, identifier-change refusal, and membership add and remove across roles, plus
      a test asserting no content column exists or is written.

### The optional change relay

- [ ] The server never attempts to decrypt, unpack or inspect a package, and stores no metadata beyond the permitted
      list.
- [ ] Replaying an upload with the same idempotency key creates nothing and returns the first result.
- [ ] A non-member device receives 404 for a package that exists, and every access is logged.
- [ ] Tests: route tests for upload success, oversize, relay-disabled project, never-relay project, replay, listing
      across a cursor boundary, download, and cross-project isolation.
- [ ] A fully acknowledged package is gone immediately, not at the next job run.
- [ ] Replaying an acknowledgement is a no-op, including after the package has been purged.
- [ ] The vectors returned match exactly what was pushed and acknowledged.
- [ ] Tests: unit tests over vector comparison; integration tests for partial acknowledgement, completion with
      delete, idempotent replay, and a device revoked mid-flight no longer counting towards completeness.
- [ ] Advancing the clock past the window removes packages that no device ever fetched, and reports how many and how
      old.
- [ ] A configured retention window above the hard maximum stops the process at boot.
- [ ] Exceeding a storage ceiling returns a clear, actionable error rather than filling the disk.
- [ ] Tests: tests driving the injected clock across the acknowledgement and expiry paths, and quota tests below, at
      and above each ceiling.

### AI custody and the proxy

- [ ] Adding a provider is one implementation and one configuration value, with no route change.
- [ ] A key cannot be retrieved through any endpoint, including error paths.
- [ ] Tests: a contract suite every implementation must pass, driven by the fake across success, failure, timeout and
      malformed output; a test scanning every route response and log line for key patterns.
- [ ] No image, audio or extracted text is written to disk, database or cache, and no log line contains payload
      content.
- [ ] A runaway client cannot exceed the organisation budget, because the limit is not on the client.
- [ ] A dead provider returns a typed, queueable error within the timeout rather than hanging a field device.
- [ ] Tests: route tests asserting nothing is persisted and that logging is metadata-only; quota tests below, at and
      above each limit; timeout, retry and breaker-transition tests against the fake provider.

### Audit and the API contract

- [ ] Every privileged action is attributable to an actor and a time, and rolling back the action rolls back its row.
- [ ] Storage growing while purge counts stay flat is visible immediately.
- [ ] Tests: tests asserting exactly one row per action with actor, target and outcome, and tests asserting each
      counter moves for its event and that no label leaks a forbidden field.
- [ ] The document and the server never disagree, because a test proves it on every run.
- [ ] A route changed without the document fails continuous integration, and the fixture proves it.
- [ ] Tests: the contract suite green against the running server and red against the drift fixture, reporting every
      mismatch with route and field rather than stopping at the first.

### Shipping the server

- [ ] An operator can leave the product entirely, taking everything the server holds, in one command.
- [ ] Destroy cannot run without an explicit organisation name and a second confirmation.
- [ ] The runbook states plainly that server backups contain accounts and metadata, never projects.
- [ ] A red pipeline blocks merging.
- [ ] Tests: command tests over a seeded database for export and destroy; a smoke test that builds the image and
      passes its health check; a pipeline run proving the gate fails when any single stage fails.

### The app side

- [ ] A signed-in device works for the full cached period with no connectivity and never shows a sign-in screen again.
- [ ] An unreachable server changes nothing about what the app will let a user do, and says so in one quiet line.
- [ ] No token, key or organisation identifier is written anywhere but secure storage.
- [ ] Records captured before enrolment keep their operator attribution and gain the account identity.
- [ ] Tests: unit tests over the enrolment state machine and over sign-in, silent refresh, expiry and offline fallback.
- [ ] Tests: a test asserting no credential reaches the database, a log or an export, and a test for operator-profile
      reconciliation.
- [ ] The interface never offers an action the server will refuse, and the role matrix exists in exactly one place.
- [ ] A device 45 days offline, past both cache lifetimes, still captures, reviews, edits and exports the projects it
      holds, and refuses only relay, the AI proxy and a role change, saying which in plain language.
- [ ] No code path anywhere in the app blocks capture on an authority check.
- [ ] Tests: a table test per role over the capability list, compared against the server's matrix; unit tests over all
      four authority states and every capability; a clock-advance test proving expiry never disables capture or
      export.
- [ ] Relayed packages merge through exactly the same preview and conflict path as a hand-carried bundle.
- [ ] Relay is off until a project manager turns it on, and a never-relay project offers no way to send.
- [ ] What has been queued, sent and purged is always visible for a project.
- [ ] Tests: an integration test relaying between two local databases through a fake server, including a replayed
      push, plus widget tests for each relay control and the queue view.
- [ ] A fresh install performs AI extraction with no key ever entered on the device.
- [ ] Choosing the proxy or a device key changes no code in any feature that uses AI.
- [ ] No response, error path or log line can bring a provider key onto the device.
- [ ] Tests: the same interface suite the direct provider passes, run against the proxy with a fake server, including
      timeout, breaker-open and quota-exceeded responses queueing rather than failing the capture.

## Out of scope

- Widening the closed package metadata list of BE-RELAY-06. A further column on a package, acknowledgement or vector
  row needs its own task and a written justification, because the closed list is what makes "the server cannot read a
  package" checkable rather than merely intended.
- The release gate over both artefacts. This phase's own gate — `npm run verify` for the server and
  `dart run tool/verify.dart --fast` for the app — closes each task here; the suites, the pipeline and the run proving
  a required backend is never a required connection belong to 120 · Testing and release.

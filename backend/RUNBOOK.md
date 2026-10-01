# Backend runbook

One container serves one organisation. The device remains the store of record. This server holds accounts, membership and optional relay metadata. It does not hold project content.

## Deploy

Set `DATABASE_URL` and `TOKEN_SECRET` in the environment. Do not bake them into the image. Apply migrations with an explicit command before serving traffic:

```bash
npm run admin -- migrate
```

The process does not migrate on boot. Readiness stays failed until the pool connects and the secret store is present.

The image compiles TypeScript in a build stage and starts `node dist/src/server.js`; it needs no runtime compiler or package download. `.dockerignore` excludes host dependencies, generated output and secret files. Build with `docker compose build backend`. Start the database first, then use the image's compiled CLI with a migration account: `docker compose run --rm -e DATABASE_URL=<migration-url> backend node dist/src/cli/admin.js migrate`. Bootstrap the first administrator with `npm run admin -- bootstrap --organisation <name> --email <address> --password-file <private-file>` locally, or use the same `node dist/src/cli/admin.js` command in the image. The password file is operator-controlled and must be removed after bootstrap. Start the backend only after these deliberate steps.

Compose requires `DATABASE_PASSWORD`, `DATABASE_URL` and `TOKEN_SECRET` instead of shipping usable placeholder credentials. The database's bootstrap user owns migrations; `DATABASE_URL` must name a separately provisioned runtime user. Give that user schema usage and the required table CRUD permissions, excluding audit/security update and delete; revoke schema/database CREATE privileges from it and PUBLIC. Migrations run with the owner account, never the runtime account. The named database volume preserves identity across container restarts. Keep PostgreSQL unexposed outside the private compose network. Terminate HTTPS in the deployment's reverse proxy and retain HSTS; do not expose this internal HTTP listener directly to the public network.

Grant runtime `SELECT, INSERT` on `audit_events, security_events`, the required CRUD on the other application tables, and no `TRUNCATE`. The confirmed destroy command uses the owner administration URL. The runtime role cannot bypass append-only event protection.

## Environment reference

All numeric resource/session/time limits are positive safe integers no greater than 2,147,483,647; `PORT` permits zero for an ephemeral test listener and otherwise is at most 65,535. Quota counts/budgets have the separate non-negative rules below.

| Variable                             | Default                 | Meaning                                                                                                         |
| ------------------------------------ | ----------------------- | --------------------------------------------------------------------------------------------------------------- |
| `DATABASE_URL`                       | Required                | PostgreSQL runtime connection; owner URL only for administration                                                |
| `TOKEN_SECRET`                       | Required                | High-entropy signing secret supplied by the operator                                                            |
| `PORT`                               | 8080                    | Internal listener port                                                                                          |
| `ACCESS_TTL_SECONDS`                 | 900                     | Access token lifetime                                                                                           |
| `REFRESH_TTL_SECONDS`                | 2592000                 | Refresh token lifetime                                                                                          |
| `RETENTION_DAYS`                     | 30                      | Organisation maximum, from 1 through 90 days                                                                    |
| `RATE_LIMIT_AUTH`                    | 10                      | Authentication requests per client per minute                                                                   |
| `RATE_LIMIT_GENERAL`                 | 120                     | General requests per client per minute                                                                          |
| `RATE_LIMIT_BUCKET_LIMIT`            | 10000                   | Maximum active addresses per limiter group (1–1000000); additional addresses receive 429 until a bucket expires |
| `BODY_LIMIT_BYTES`                   | 1000000                 | General JSON request limit                                                                                      |
| `AI_BODY_LIMIT_BYTES`                | 27000000                | AI JSON limit, at least the general limit                                                                       |
| `CORS_ORIGINS`                       | Empty                   | Comma-separated exact browser origins                                                                           |
| `PACKAGE_MAX_BYTES`                  | 20000000                | Maximum relay ciphertext per package                                                                            |
| `STORAGE_CEILING_BYTES`              | 50000000                | Retained ciphertext limit per project                                                                           |
| `ORGANISATION_STORAGE_CEILING_BYTES` | 500000000               | Retained ciphertext limit per organisation                                                                      |
| `ARGON_MEMORY_KIB`                   | 19456                   | Argon2id memory                                                                                                 |
| `ARGON_ITERATIONS`                   | 2                       | Argon2id passes                                                                                                 |
| `ARGON_PARALLELISM`                  | 1                       | Argon2id lanes                                                                                                  |
| `LOCKOUT_FAILURES`                   | 5                       | Failures before account/address lockout                                                                         |
| `LOCKOUT_WINDOW_MS`                  | 60000                   | Lockout duration                                                                                                |
| `AI_TIMEOUT_MS`                      | 8000                    | Provider attempt timeout, at most 120000 ms                                                                     |
| `AI_RETRY_LIMIT`                     | 2                       | Extra attempts, from 0 through 5                                                                                |
| `AI_BREAKER_THRESHOLD`               | 3                       | Transient failures before opening the breaker                                                                   |
| `AI_PROVIDER_URL`                    | Gemini v1beta HTTPS URL | Trusted compatible provider endpoint                                                                            |
| `AI_PROVIDER_KEY`                    | Empty                   | Server-held provider credential; empty disables AI                                                              |
| `AI_PROVIDER_MODEL`                  | default                 | Required when a provider key is configured                                                                      |
| `API_VERSION`                        | 1                       | HTTP API version                                                                                                |
| `BUILD_VERSION`                      | dev                     | Version reported by the running build                                                                           |
| `POOL_MAX`                           | 10                      | Maximum database connections                                                                                    |
| `DATABASE_CONNECT_TIMEOUT_MS`        | 5000                    | Connection establishment timeout                                                                                |
| `DATABASE_STATEMENT_TIMEOUT_MS`      | 15000                   | Database statement timeout                                                                                      |
| `PURGE_INTERVAL_MS`                  | 60000                   | Serial scheduled cleanup interval                                                                               |
| `PURGE_BATCH_SIZE`                   | 100                     | Maximum rows of each cleanup category in a transaction                                                          |
| `READY`                              | true                    | Operator readiness override                                                                                     |
| `DATABASE_PASSWORD`                  | Required by compose     | Database owner password; not the runtime application credential                                                 |

## Upgrade

Apply the next numbered migration forward only. A changed checksum or an out-of-order file refuses to run. Accounts, memberships and audit rows from the previous schema stay in place.

Migration `006_account_token_purpose.sql` distinguishes invitations from password resets. Earlier tokens default to invitations: existing invitation links remain valid only for invited accounts; older reset links must be reissued. Acceptance rechecks purpose, expiry, account state and organisation inside the same transaction that consumes the token. Registration sends the same `200 { accepted: true }` response for new and existing addresses, without an account identifier or Location header.

`007_refresh_family_scope.sql` isolates new sign-ins into distinct refresh chains. Legacy rows keep their previous user/device scope until they expire. `008_runtime_settings.sql` stores non-usable digests and safe deployment metadata to detect key/policy changes. `009_transient_retention.sql` makes lockout and acknowledgement expiry explicit. `010_scoped_pagination.sql` adds composite indexes for bounded account, project, device, relay and usage pages, replacing superseded single-column indexes without changing data. Apply through 010 before starting the current server. Startup warms Argon verification once; unknown and wrong-password logins each perform one verification, and a successful login upgrades old hash parameters.

## API list pages

Project, membership, device, relay-package and AI-usage lists return `items` and `nextCursor`; organisation users retain `users` and `nextCursor`. Every list accepts `limit` (default 50, maximum 100) and `cursor`. Continue with the returned cursor until it is null. Identifier keysets survive deletion; relay cursors also include the creation time so purging or acknowledging the previous package cannot restart the list. Clients should treat cursors as opaque. `/auth/me` returns the complete grants snapshot the device needs for offline authority.

## Password reset

`POST /api/v1/auth/reset` with an address records a request and returns the same acceptance for every address. An organisation operator reviews `password_reset_requested` audit entries and issues a capability with `npm run admin -- reset-password --email <address> --actor <operator-identity> --out <new-private-file>`. It is valid for one hour, stored only as a hash by the server, and never printed to logs or the console. Provide that file's token to the account owner using the organisation's established private channel, then remove the file. Windows file permissions are controlled by the directory ACL; choose a private directory. The account owner submits it with the new password to the reset endpoint. Consumption is atomic, replay/expiry is refused, and all of that user's refresh families are revoked. This deployment does not promise automatic email delivery.

## Rotate a key

Replace `TOKEN_SECRET` and restart. Existing access tokens stop verifying. Users sign in again. Provider keys live in the key holder, not in the database and not in the client.

Startup records key and policy initialization/change with actor `deployment`, a timestamp, target and applied outcome. Only configured state and safe policy values enter the event; neither the key nor its digest enters logs, responses or exports. An unchanged restart creates no duplicate configuration events.

## Change retention

Set `RETENTION_DAYS` between 1 and 90. A value above 90 refuses to boot. Project retention cannot exceed the organisation maximum or 90 days.

On startup the configured maximum is applied transactionally to the organisation, project windows and existing package/acknowledgement expiry. Reducing it shortens existing expiry; increasing it never extends a package already in flight. Project changes audit the before/after relay, never-relay and retention settings.

## A purge failed

Read the purge report: `deleted`, `bytesReclaimed`, `oldestAgeSeconds`, `transientDeleted`, `failures`. A non-zero `failures` means rows were left behind and produces an error log. Cleanup deletes bounded batches of expired ciphertext and token/replay/lockout metadata, preserving unexpired state and durable version counters. Package removal cascades to acknowledgements. Every run records its counts and outcome; the storage gauge reads current database aggregates. Fix the cause and run the job again. Do not delete audit rows.

## Restore

Restore accounts, devices, memberships, roles, audit and package metadata. Projects are not included in a backup. Captured records stay on the devices. An export says so in its README.

`npm run admin -- export --out <new-directory>` writes one metadata snapshot covering all account, project registration, relay, audit/security, usage and operational tables. It refuses to overwrite existing output. It excludes ciphertext and usable credential material, including password/token hashes and key fingerprints. This is a portable metadata export, not a credential restore or a project backup. `npm run admin -- destroy --confirm <organisation-name> --again <organisation-name>` refuses a mismatched confirmation or a database containing another organisation. With the owner administration URL, it transactionally clears every organisation table, including ciphertext, events, replay/lockout state and configuration metadata; append-only triggers remain enabled for ordinary runtime writes. Only migration history remains so the empty deployment can be bootstrapped again.

Database backups must exclude the ciphertext in `relay_blobs` (`pg_dump --exclude-table-data=relay_blobs`). A restored package-metadata row does not reconstruct project data; an absent/expired blob is fetched again from an authoritative device. Never back up or archive relay ciphertext. Run logs through the deployment's bounded rotation/retention policy rather than keeping them indefinitely.

## Unexpected growth

If storage grows while purge stays flat, retention is broken. Investigate before adding disk or another instance.

## Browser access (CORS)

The web build is served from its own origin, so browsers only reach this API when that origin is allow-listed. Set `CORS_ORIGINS` to a comma-separated list of exact origins, for example `https://app.example.com,http://localhost:5000`. Entries must be `http` or `https` origins without a path; anything else refuses to boot. The default is empty: the server sends no CORS headers and only native clients can call it.

For a listed origin, every response carries `Access-Control-Allow-Origin` for that origin, `Vary: Origin` and `Access-Control-Expose-Headers: Retry-After, X-Request-Id`. Preflight `OPTIONS` requests are answered with `204` before authentication and rate limiting, allowing `GET, POST, PATCH, DELETE`, the `Authorization`, `Content-Type`, `X-Api-Version` and `Idempotency-Key` headers and a 600-second `Access-Control-Max-Age`. A preflight from an unlisted origin receives `403`. Credentials are never allowed; clients send bearer tokens without cookies.

## Request size limits

`BODY_LIMIT_BYTES` (default 1 MB) bounds every JSON body except the AI routes. `/api/v1/ai/*` carries inline images and audio, so it has its own `AI_BODY_LIMIT_BYTES` (default 27 MB, and never below `BODY_LIMIT_BYTES`). The default leaves room for Gemini's 20 MB inline request plus the JSON and base64 encoding the device adds in transit; lower it if the chosen model accepts less. AI bodies are read only after the access token is verified, so unauthenticated clients cannot make the server buffer them. Relay packages use `PACKAGE_MAX_BYTES`. An oversized body receives `413 payload_too_large`.

## AI provider and device enrolment

The shipped provider calls Google's Gemini `generateContent` REST API directly. No additional proxy service or client-side key is required. Configure `AI_PROVIDER_KEY` in the server secret environment and `AI_PROVIDER_MODEL` with an available image/audio-capable model from your Gemini account. `AI_PROVIDER_URL` defaults to `https://generativelanguage.googleapis.com/v1beta`; override it only for a compatible, trusted HTTPS endpoint. An absent key makes AI unavailable; it never produces a fabricated extraction.

The device composes a structured request containing `instructions`, quoted `data`, inline `media` (`mimeType`, `base64`) and `responseMimeType`. The server's provider adapter only maps these onto `systemInstruction`, user content parts and generation configuration, and sends no other request field. It adds no prompts or project content, uploads no provider files, and returns the completed text with its model. No request flag controls provider-side retention; Google's Gemini API terms for the configured account govern it, so use a billed project for organisation data. Responses containing the configured key, blocked/truncated replies and malformed responses are rejected. The quota applies to every call. Retry and the circuit breaker cover only timeouts, throttling and provider faults: a payload the provider refuses returns 400 (413 when too large), and an absent or refused key or an unknown `AI_PROVIDER_MODEL` returns 503 `unavailable`; neither is retried or counted by the breaker.

Provider contract references: [generateContent REST](https://ai.google.dev/api/generate-content), [inline audio](https://ai.google.dev/gemini-api/docs/audio). Contract tests inject fetch and never require a provider credential or make billable requests. A live extraction acceptance requires the organisation's configured model and key.

## AI quotas and accounting

The server checks project and organisation limits across all users before dispatch. A short transaction reads aggregate totals and records a usage reservation, preventing simultaneous callers or replicas from taking the final allowance twice. The provider runs outside that transaction. Only project, user, model, byte size, duration, outcome, charge and time are stored; no request or response content is retained.

| Environment variable                  | Default | Meaning                                                 |
| ------------------------------------- | ------: | ------------------------------------------------------- |
| `AI_PROJECT_REQUEST_LIMIT`            |  10,000 | Lifetime requests per project                           |
| `AI_ORGANISATION_REQUEST_LIMIT`       | 100,000 | Lifetime requests across organisation projects          |
| `AI_PROJECT_DAILY_REQUEST_LIMIT`      |     100 | Requests per project per UTC day                        |
| `AI_ORGANISATION_DAILY_REQUEST_LIMIT` |   1,000 | Organisation requests per UTC day                       |
| `AI_PROJECT_BUDGET`                   |     100 | Lifetime conservative charges per project               |
| `AI_ORGANISATION_BUDGET`              |   1,000 | Lifetime organisation charges                           |
| `AI_PROJECT_DAILY_BUDGET`             |      10 | Project charges per UTC day                             |
| `AI_ORGANISATION_DAILY_BUDGET`        |     100 | Organisation charges per UTC day                        |
| `AI_REQUEST_COST_CEILING`             |       0 | Operator-supplied upper cost bound per provider attempt |

Counts are non-negative safe integers; budgets are finite non-negative values. All budget values use the same operator-chosen currency/unit. Set `AI_REQUEST_COST_CEILING` from the configured model's pricing and the largest allowed input/output. Proxy dispatch permits only `default` (the configured model) or that exact model name, so a client cannot choose an unbounded price tier. Zero leaves proxy dispatch unavailable and `auth/me.aiAvailable` false, so an unknown monetary price is never reported as free. Each request reserves the ceiling multiplied by `AI_RETRY_LIMIT + 1`. Failed, timed-out and interrupted requests retain their reservation because a failed reply does not prove the provider charged nothing. Daily limits reset at midnight UTC; lifetime accounting stays intact. The usage endpoint and AI cost metric report this conservative charge, not an invoice or fabricated byte-to-money estimate. Reconcile it against the provider's bill. The actual billing guarantee depends on the correctness of the configured upper bound.

## Verification

`npm run verify` runs formatting, lint, strict types, all unit/HTTP/contract tests, dependency advisory and source-secret scans. Set `DATABASE_URL` to an ephemeral PostgreSQL instance to run database integration and upgrade tests; without it those tests explicitly report SKIP. Set `RUN_DOCKER_SMOKE=true` with a working Docker daemon to build the production image, migrate a disposable PostgreSQL container and assert liveness, readiness, image health and non-root execution. The smoke test removes only its uniquely named containers, network and image. A local gate with these skips is not database/image deployment acceptance.

Task 024 adds the pinned development dependency `yaml` 2.9.1 (ISC licence) to parse the OpenAPI contract. It replaces the earlier regular expression path list, enabling HTTP-method and request/response-schema comparisons and a real drift fixture. It is omitted from the runtime image.

Build Flutter with `--dart-define=BACKEND_URL=https://your-server` to provide the organisation address. A self-hosted install can instead save that HTTPS address in Organisation settings. The server infers its single organisation at sign-in, so its identifier need not be compiled into the client. Credentials, account/grants and rotating refresh tokens are held only in platform secure storage. Startup restores that cache without network access, then attempts silent refresh; loss of connectivity does not erase local work or re-open sign-in.

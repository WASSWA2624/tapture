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

| Variable                             | Default                   | Meaning                                                                                                            |
| ------------------------------------ | ------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `DATABASE_URL`                       | Required                  | PostgreSQL runtime connection; owner URL only for administration                                                   |
| `TOKEN_SECRET`                       | Required                  | High-entropy signing secret supplied by the operator                                                               |
| `PORT`                               | 8080                      | Internal listener port                                                                                             |
| `ACCESS_TTL_SECONDS`                 | 900                       | Access token lifetime                                                                                              |
| `REFRESH_TTL_SECONDS`                | 2592000                   | Refresh token lifetime                                                                                             |
| `RETENTION_DAYS`                     | 30                        | Organisation maximum, from 1 through 90 days                                                                       |
| `RATE_LIMIT_AUTH`                    | 10                        | Authentication requests per client per minute                                                                      |
| `RATE_LIMIT_GENERAL`                 | 120                       | General requests per client per minute                                                                             |
| `RATE_LIMIT_BUCKET_LIMIT`            | 10000                     | Maximum active addresses per limiter group (1–1000000); additional addresses receive 429 until a bucket expires    |
| `BODY_LIMIT_BYTES`                   | 1000000                   | General JSON request limit                                                                                         |
| `AI_BODY_LIMIT_BYTES`                | 27000000                  | AI JSON limit, at least the general limit                                                                          |
| `CORS_ORIGINS`                       | Empty                     | Comma-separated exact browser origins                                                                              |
| `PACKAGE_MAX_BYTES`                  | 20000000                  | Maximum relay ciphertext per package                                                                               |
| `STORAGE_CEILING_BYTES`              | 50000000                  | Retained ciphertext limit per project                                                                              |
| `ORGANISATION_STORAGE_CEILING_BYTES` | 500000000                 | Retained ciphertext limit per organisation                                                                         |
| `ARGON_MEMORY_KIB`                   | 19456                     | Argon2id memory                                                                                                    |
| `ARGON_ITERATIONS`                   | 2                         | Argon2id passes                                                                                                    |
| `ARGON_PARALLELISM`                  | 1                         | Argon2id lanes                                                                                                     |
| `LOCKOUT_FAILURES`                   | 5                         | Failures before account/address lockout                                                                            |
| `LOCKOUT_WINDOW_MS`                  | 60000                     | Lockout duration                                                                                                   |
| `AI_TIMEOUT_MS`                      | 8000                      | Provider attempt timeout, at most 120000 ms                                                                        |
| `AI_RETRY_LIMIT`                     | 2                         | Extra attempts, from 0 through 5                                                                                   |
| `AI_BREAKER_THRESHOLD`               | 3                         | Transient failures before opening the breaker                                                                      |
| `AI_PROVIDER_URL`                    | Gemini v1beta HTTPS URL   | Trusted compatible provider endpoint                                                                               |
| `AI_PROVIDER_KEY`                    | Empty                     | Server-held provider credential; empty disables AI                                                                 |
| `AI_PROVIDER_MODEL`                  | default                   | Required when a provider key is configured                                                                         |
| `AI_PROVIDER`                        | gemini                    | Managed provider: `gemini` or `openai`; never changed automatically                                                |
| `AI_GEMINI_MODEL`                    | Managed Gemini model      | Configured low-cost Gemini base model; required for personal Gemini when managed provider differs                  |
| `AI_OPENAI_MODEL`                    | Managed OpenAI model      | Configured low-cost OpenAI base model; required for personal OpenAI when managed provider differs                  |
| `AI_OPENAI_URL`                      | https://api.openai.com/v1 | Trusted Responses-compatible HTTPS endpoint                                                                        |
| `AI_CREDENTIAL_ENCRYPTION_KEY`       | Empty                     | Secret 256-bit AES key as 64 hexadecimal characters; empty disables personal credential saving                     |
| `AI_MODEL_COST_CEILINGS`             | `{}`                      | JSON map of enabled `provider:model` to conservative attempt ceilings; non-base entries require user cost approval |
| `AI_MAX_OUTPUT_TOKENS`               | 4096                      | Maximum provider output tokens, from 1 through 32768; include this bound when setting ceilings                     |
| `API_VERSION`                        | 1                         | HTTP API version                                                                                                   |
| `BUILD_VERSION`                      | dev                       | Version reported by the running build                                                                              |
| `POOL_MAX`                           | 10                        | Maximum database connections                                                                                       |
| `DATABASE_CONNECT_TIMEOUT_MS`        | 5000                      | Connection establishment timeout                                                                                   |
| `DATABASE_STATEMENT_TIMEOUT_MS`      | 15000                     | Database statement timeout                                                                                         |
| `PURGE_INTERVAL_MS`                  | 60000                     | Serial scheduled cleanup interval                                                                                  |
| `PURGE_BATCH_SIZE`                   | 100                       | Maximum rows of each cleanup category in a transaction                                                             |
| `READY`                              | true                      | Operator readiness override                                                                                        |
| `DATABASE_PASSWORD`                  | Required by compose       | Database owner password; not the runtime application credential                                                    |

## Upgrade

Apply the next numbered migration forward only. A changed checksum or an out-of-order file refuses to run. Accounts, memberships and audit rows from the previous schema stay in place.

Migration `006_account_token_purpose.sql` distinguishes invitations from password resets. Earlier tokens default to invitations: existing invitation links remain valid only for invited accounts; older reset links must be reissued. Acceptance rechecks purpose, expiry, account state and organisation inside the same transaction that consumes the token. Registration sends the same `200 { accepted: true }` response for new and existing addresses, without an account identifier or Location header.

`007_refresh_family_scope.sql` isolates new sign-ins into distinct refresh chains. Legacy rows keep their previous user/device scope until they expire. `008_runtime_settings.sql` stores non-usable digests and safe deployment metadata to detect key/policy changes. `009_transient_retention.sql` makes lockout and acknowledgement expiry explicit. `010_scoped_pagination.sql` adds composite indexes for bounded account, project, device, relay and usage pages, replacing superseded single-column indexes without changing data. `011_ai_processing.sql` adds encrypted personal credentials, metadata-only processing receipts and nullable provider/token attribution beside existing usage; it preserves legacy rows. Startup warms Argon verification once; unknown and wrong-password logins each perform one verification, and a successful login upgrades old hash parameters.

## Supported AI providers

`AI_PROVIDER_CATALOGUE` is an optional JSON array of additional administrator-configured providers. Missing, empty or `[]` retains the existing Gemini/OpenAI configuration. Additional entries cannot use the retained `gemini` or `openai` IDs. This supports only the existing Gemini generateContent and OpenAI Responses wire protocols; an arbitrary API key does not define a protocol. No device may supply an endpoint.

Each object requires `id` (lowercase letter followed by up to 63 lowercase letters, digits or hyphens), `label` (1–128 characters), `protocol` (`gemini-generate-content` or `openai-responses`), `baseUrl` (HTTPS with no credentials, query or fragment), `authMode` (`required` or `none`), `models` (unique nonempty model identifiers), `model` (one of those models), `operations` (unique values from `ocr`, `extract`, `refine`, `transcribe`), `currency` (exactly `configured`) and `modelCostCeilings` (one positive finite attempt ceiling for every model). Models use letters, digits, dot, underscore or hyphen. The wire identifier `default` selects the configured base model; it may appear in `models` only when `model` is also `default`. Unknown fields, IDs, protocols and incomplete costs fail boot. Operations must reflect the configured endpoint's existing protocol/media support; the Responses adapter retains its photo/text restriction.

For example, a keyless deployment endpoint using the existing Responses protocol:

```json
[
  {
    "id": "field-ai",
    "label": "Field AI",
    "protocol": "openai-responses",
    "baseUrl": "https://ai.example.com/v1",
    "authMode": "none",
    "model": "small",
    "models": ["small", "large"],
    "operations": ["ocr", "extract", "refine"],
    "currency": "configured",
    "modelCostCeilings": { "small": 0.01, "large": 0.2 }
  }
]
```

Set `authMode` to `required` for personal credentials held by the existing authenticated encrypted-custody service; never include a secret in this JSON. Keyless requests send `{ "kind": "managed", "provider": "field-ai" }` as billing, route to that exact configured provider, omit both authentication headers and never look up a credential. Positive configured costs, project/organisation quotas, explicit escalation approval and authorization still apply. Entering or searching the catalogue performs no model call. Redirects are refused; only the configured endpoint is contacted.

The provider catalogue exposes labels, protocol/authentication mode, supported operations/models, cost ceilings and availability, never endpoint URLs or secrets. New processing receipts bind the provider/account/model to a fingerprint of the nonsecret configuration. Changing endpoint, protocol, models, capabilities or costs refuses reuse of that receipt identifier. Existing built-in receipt hashes are recognized only when an already-stored receipt exists and return its previous recovery state without redispatch. No response payload becomes durable.

Migration `012_ai_provider_catalogue.sql` widens the credential provider-ID constraint without changing credential ciphertext, revisions, usage or receipts. Apply through 012 deliberately before starting this server; do not edit migration 011. The upgrade test seeds 011, verifies exact row preservation after 012, and checks transactional rollback on a failed migration. This development change does not authorize a production migration or deployment.

## API list pages

Project, membership, device, relay-package and AI-usage lists return `items` and `nextCursor`; organisation users retain `users` and `nextCursor`. Every list accepts `limit` (default 50, maximum 100) and `cursor`. Continue with the returned cursor until it is null. Identifier keysets survive deletion; relay cursors also include the creation time so purging or acknowledging the previous package cannot restart the list. Clients should treat cursors as opaque. `/auth/me` returns the complete grants snapshot the device needs for offline authority.

## Password reset

`POST /api/v1/auth/reset` with an address records a request and returns the same acceptance for every address. An organisation operator reviews `password_reset_requested` audit entries and issues a capability with `npm run admin -- reset-password --email <address> --actor <operator-identity> --out <new-private-file>`. It is valid for one hour, stored only as a hash by the server, and never printed to logs or the console. Provide that file's token to the account owner using the organisation's established private channel, then remove the file. Windows file permissions are controlled by the directory ACL; choose a private directory. The account owner submits it with the new password to the reset endpoint. Consumption is atomic, replay/expiry is refused, and all of that user's refresh families are revoked. This deployment does not promise automatic email delivery.

## Rotate a key

Replace `TOKEN_SECRET` and restart. Existing access tokens stop verifying. Users sign in again. Managed provider keys stay in the secret environment. Personal provider keys are encrypted in `ai_credentials`, bound with AES-256-GCM associated data to user, provider and credential revision; only an explicitly chosen adapter receives plaintext during a request. Neither keys nor ciphertext enter responses, logs or metadata exports.

Generate `AI_CREDENTIAL_ENCRYPTION_KEY` with a cryptographic random generator, hold it in the deployment secret store and keep it separate from database access. Preserve this key across ordinary restarts. Replacing it makes previous personal credentials unreadable: arrange for users to remove/re-enter them after rotation. Rotate a personal provider key by saving its replacement in the app, which assigns a new revision and prevents old processing identifiers from silently charging the new billing account. Rotate managed provider credentials in the environment; old receipt bindings similarly refuse a changed credential/account.

Startup records key and policy initialization/change with actor `deployment`, a timestamp, target and applied outcome. Only configured state and safe policy values enter the event; neither the key nor its digest enters logs, responses or exports. An unchanged restart creates no duplicate configuration events.

## Change retention

Set `RETENTION_DAYS` between 1 and 90. A value above 90 refuses to boot. Project retention cannot exceed the organisation maximum or 90 days.

On startup the configured maximum is applied transactionally to the organisation, project windows and existing package/acknowledgement expiry. Reducing it shortens existing expiry; increasing it never extends a package already in flight. Project changes audit the before/after relay, never-relay and retention settings.

## A purge failed

Read the purge report: `deleted`, `bytesReclaimed`, `oldestAgeSeconds`, `transientDeleted`, `failures`. A non-zero `failures` means rows were left behind and produces an error log. Cleanup deletes bounded batches of expired ciphertext and token/replay/lockout metadata, preserving unexpired state and durable version counters. Package removal cascades to acknowledgements. Every run records its counts and outcome; the storage gauge reads current database aggregates. Fix the cause and run the job again. Do not delete audit rows.

## Restore

Restore accounts, devices, memberships, roles, audit and package metadata. Projects are not included in a backup. Captured records stay on the devices. An export says so in its README.

`npm run admin -- export --out <new-directory>` writes one metadata snapshot covering all account, project registration, relay, audit/security, usage and operational tables. It refuses to overwrite existing output. It excludes ciphertext and usable credential material, including password/token hashes and key fingerprints. This is a portable metadata export, not a credential restore or a project backup. `npm run admin -- destroy --confirm <organisation-name> --again <organisation-name>` refuses a mismatched confirmation or a database containing another organisation. With the owner administration URL, it transactionally clears every organisation table, including ciphertext, events, replay/lockout state and configuration metadata; append-only triggers remain enabled for ordinary runtime writes. Only migration history remains so the empty deployment can be bootstrapped again.

Database backups must exclude ciphertext in `relay_blobs` and personal credentials in `ai_credentials` (`pg_dump --exclude-table-data=relay_blobs --exclude-table-data=ai_credentials`). A restored package-metadata row does not reconstruct project data; an absent/expired blob is fetched again from an authoritative device. Users re-enter their personal credentials after restore. Never back up or archive relay ciphertext. Run logs through the deployment's bounded rotation/retention policy rather than keeping them indefinitely.

## Unexpected growth

If storage grows while purge stays flat, retention is broken. Investigate before adding disk or another instance.

## Browser access (CORS)

The web build is served from its own origin, so browsers only reach this API when that origin is allow-listed. Set `CORS_ORIGINS` to a comma-separated list of exact origins, for example `https://app.example.com,http://localhost:5000`. Entries must be `http` or `https` origins without a path; anything else refuses to boot. The default is empty: the server sends no CORS headers and only native clients can call it.

For a listed origin, every response carries `Access-Control-Allow-Origin` for that origin, `Vary: Origin` and `Access-Control-Expose-Headers: Retry-After, X-Request-Id`. Preflight `OPTIONS` requests are answered with `204` before authentication and rate limiting, allowing `GET, POST, PUT, PATCH, DELETE`, the `Authorization`, `Content-Type`, `X-Api-Version` and `Idempotency-Key` headers and a 600-second `Access-Control-Max-Age`. A preflight from an unlisted origin receives `403`. Credentials are never allowed; clients send bearer tokens without cookies.

## Request size limits

`BODY_LIMIT_BYTES` (default 1 MB) bounds ordinary JSON bodies and credential saves. AI processing routes carry inline images and audio, so they use `AI_BODY_LIMIT_BYTES` (default 27 MB, and never below `BODY_LIMIT_BYTES`). Versioned requests may base64-encode the complete JSON envelope to preserve exact hash bytes; account for that additional encoding overhead when choosing image/request caps. Lower the limit if the selected model accepts less. AI bodies are read only after the access token is verified, so unauthenticated clients cannot make the server buffer them. Relay packages use `PACKAGE_MAX_BYTES`. An oversized body receives `413 payload_too_large`.

## AI provider and device enrolment

Managed AI is the default. Choose `AI_PROVIDER=gemini` or `openai`, set `AI_PROVIDER_KEY` in the secret environment and configure an inexpensive extraction model with `AI_PROVIDER_MODEL`. This variable is required whenever the managed key is configured, including when `AI_GEMINI_MODEL` or `AI_OPENAI_MODEL` overrides that provider's base selection. Configure those provider-specific variables to enable or override their base models, including a different provider used by personal accounts. Set a reviewed `AI_REQUEST_COST_CEILING` and spending limits before enabling calls. An absent managed key leaves managed calls unavailable, while a user can explicitly choose an enabled personal account. There is never a provider, model or billing fallback. `AI_PROVIDER_URL` defaults to Gemini v1beta; `AI_OPENAI_URL` defaults to OpenAI v1. Override either only with a compatible trusted HTTPS destination.

The device composes `instructions`, quoted `data`, inline `media` (`mimeType`, `base64`) and `responseMimeType`. Adapters preserve that division so captions/transcripts/templates remain untrusted data. Gemini maps it to `systemInstruction` and user parts; OpenAI maps it to Responses `instructions` and inline `input_text`/`input_image`, with `store:false`, `background:false` and no Files, vector store or tools. Both apply `AI_MAX_OUTPUT_TOKENS`. OpenAI accepts text/photos and existing Whisper transcripts; raw audio is explicitly refused rather than sent to another account or provider. Gemini remains available for the existing audio operation. Responses containing credentials, blocked/truncated/malformed output or an adapter changing the selected model are rejected. The app stores raw responses locally before applying validated evidence-linked proposals. Provider-side retention remains subject to the chosen account's terms; disabling response storage does not promise zero retention by the provider.

Configure exact model identifiers. When a provider reports its model (`modelVersion` for Gemini or `model` for OpenAI), it must match the selected identifier. A moving alias that resolves to a different snapshot is refused; update the configured model and reviewed cost ceiling explicitly.

Provider contract references: [generateContent REST](https://ai.google.dev/api/generate-content), [inline audio](https://ai.google.dev/gemini-api/docs/audio), [Responses API](https://developers.openai.com/api/docs/guides/migrate-to-responses), [OpenAI photo input](https://developers.openai.com/api/docs/guides/images-vision), [OpenAI data controls](https://developers.openai.com/api/docs/guides/your-data). Contract tests inject fetch and make no billable requests. Live extraction acceptance requires the organisation's configured model/key and a reviewed cost bound.

### Supported AI providers

Gemini and OpenAI retain their existing configuration. Additional administrator-configured providers must implement `gemini-generate-content` or `openai-responses`; a matching protocol does not certify every provider feature. xAI uses the existing stateless Responses adapter for `ocr`, `extract` and `refine` with text or inline photos. Its unconfigured personal identity remains unavailable until authenticated server metadata supplies the approved catalogue. No server endpoint or catalogue configuration field is exposed in the mobile UI, and selection never changes billing automatically.

The following `AI_PROVIDER_CATALOGUE` template is **non-deployable**: its cost placeholder deliberately fails boot validation. An administrator must review the exact available model identifiers, default model, provider/account terms, egress destination and positive per-attempt ceilings before replacing the placeholder with a number in the deployment's configured accounting unit. Include a ceiling for every model. `grok-4.7` is only a dated documentation/test example checked on 2026-10-08; it is neither a default deployment change nor a pricing recommendation.

```json
[
  {
    "id": "xai",
    "label": "xAI",
    "protocol": "openai-responses",
    "baseUrl": "https://api.x.ai/v1",
    "authMode": "required",
    "operations": ["ocr", "extract", "refine"],
    "models": ["grok-4.7"],
    "model": "grok-4.7",
    "currency": "configured",
    "modelCostCeilings": { "grok-4.7": "REVIEWED_POSITIVE_CEILING" }
  }
]
```

Allow outbound HTTPS to the reviewed `api.x.ai` destination when the operator explicitly enables this catalogue. Personal credentials stay in the existing server-held encrypted custody; clients receive status only. The adapter uses `Authorization: Bearer`, inline `input_text`/`input_image`, `store:false`, `background:false`, the configured timeout and `AI_MAX_OUTPUT_TOKENS`. xAI's documented image scope is JPEG/PNG, up to 20 MiB per image; fit existing request/media limits to the selected model and provider. Saved local transcripts remain text input; raw-audio `transcribe` is excluded by this catalogue and refused before upstream dispatch. No new protocol, automatic provider/account fallback, deployed configuration or live test traffic is introduced.

References checked on 2026-10-08: [xAI Responses](https://docs.x.ai/developers/rest-api-reference/inference/responses), [image understanding](https://docs.x.ai/developers/model-capabilities/images/understanding), [text generation and request-storage opt-out](https://docs.x.ai/developers/model-capabilities/text/generate-text), [Grok 4.7 example](https://docs.x.ai/developers/grok-4-7). Request-store opt-out controls retrieval of request/response history; it does not certify xAI's complete external retention policy. Repository fixtures inject every HTTP response and use positive **synthetic test ceilings**, never provider pricing.

`GET /api/v1/ai/providers` returns configured base/allowlisted models, per-model cost ceilings and account availability without credentials. `GET /api/v1/ai/credentials/:provider` reports only this authenticated user's configured state. `PUT` saves `{apiKey}` as ciphertext; `DELETE` removes that user's key and is repeatable. Saving a key never changes the selected account. Removal prevents future personal dispatch and never selects managed billing; an already reserved request is in flight and may finish. Cancel its client request to abort the provider call. Append-only audit events retain only credential presence/removal metadata. The confirmed deployment destroy removes credentials, receipts and usage; ordinary record/project deletion stays local because no server project content exists.

Versioned calls carry `processing:{version:1,projectRevision,recordId,requestHash,idempotencyKey}`. Compute lowercase SHA-256 over exact UTF-8 envelope bytes, base64-encode those same bytes as `payload`, and persist the identifier/snapshot locally before sending. The server hashes actor/device/project/operation/model/provider/billing account/revision/explicit maximum approved cost with that identity. It commits the metadata-only receipt and quota reservation atomically under the deployment advisory lock before provider dispatch. A different binding under the same key is refused with 409; simultaneous active requests share one operation, and a replica without that active request returns recovery information rather than dispatching twice.

Only an in-flight HTTP operation coalesces its promise/result; nothing retains project payloads or generated output after that operation ends. Completed receipt replay returns `409 ai_result_unavailable` once the active operation is gone. A running/failed/cancelled/timeout receipt without an active result returns `409 ai_request_uncertain`. Recover the raw response saved on the device, or explicitly approve a new attempt/identifier while acknowledging the previous attempt may have been charged. A server crash leaves the receipt intact and cannot trigger another call under that identifier. Receipts are permanent metadata tombstones until deployment destruction; expiring them would allow a delayed retry to charge twice. Keep receipts when restoring accounting metadata.

Optional `billing:{kind:'managed'|'personal',provider:'<configured provider ID>'}` selects the account explicitly; omission preserves the legacy managed path. Required-auth providers use personal custody, with managed billing also available for the configured built-in managed provider; keyless providers use managed billing bound to their exact configured ID. `model:'default'` resolves only to that provider's configured inexpensive base model. A non-base model must appear in the provider's catalogue `modelCostCeilings` (or `AI_MODEL_COST_CEILINGS` for built-ins) and supply an explicit finite `maxCost` at least its attempt ceiling. Responses expose selected provider/model/billing kind, available token counts and the conservative reserved cost. Nothing is approved by AI automatically.

## AI quotas and accounting

The server checks project and organisation limits across all users before dispatch. A short transaction reads aggregate totals and records a usage reservation, preventing simultaneous callers or replicas from taking the final allowance twice. The provider runs outside that transaction. Only project, user, provider/model/account kind, optional token counts, byte size, duration, outcome, conservative charge and time are stored; no request or response content is retained.

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

Counts are non-negative safe integers; budgets are finite non-negative values in one operator-chosen currency/unit (`currency:'configured'` in the API). Compute `AI_REQUEST_COST_CEILING` and each allowlisted model ceiling from that model's pricing, the largest admitted input and `AI_MAX_OUTPUT_TOKENS`. Zero leaves a model unavailable rather than reporting an unknown price as free. Versioned, explicitly personal/billing-selected or max-cost-approved requests reserve one attempt and never retry automatically after dispatch. Legacy requests reserve the ceiling multiplied by `AI_RETRY_LIMIT + 1`; bounded retries cover provider faults, but ambiguous timeouts/cancellation never retry. Circuit breakers are isolated by deployment, provider, billing account and model. Payload/configuration faults never retry. Failed, timed-out and interrupted requests retain their reservation because a failed reply does not prove the provider charged nothing. Daily limits reset at midnight UTC; lifetime accounting stays intact. Token counts are provider-reported usage; reserved monetary cost is a conservative upper-bound charge, not an invoice or a byte-to-money estimate. Reconcile it against provider bills. Billing guarantees depend on the correctness of the configured ceilings.

## Verification

`npm run verify` runs formatting, lint, strict types, all unit/HTTP/contract tests, dependency advisory and source-secret scans. Set `DATABASE_URL` to an ephemeral PostgreSQL instance to run database integration and upgrade tests; without it those tests explicitly report SKIP. Set `RUN_DOCKER_SMOKE=true` with a working Docker daemon to build the production image, migrate a disposable PostgreSQL container and assert liveness, readiness, image health and non-root execution. The smoke test removes only its uniquely named containers, network and image. A local gate with these skips is not database/image deployment acceptance.

Task 024 adds the pinned development dependency `yaml` 2.9.1 (ISC licence) to parse the OpenAPI contract. It replaces the earlier regular expression path list, enabling HTTP-method and request/response-schema comparisons and a real drift fixture. It is omitted from the runtime image.

Build Flutter with `--dart-define=BACKEND_URL=https://your-server` to provide the organisation address. A self-hosted install can instead save that HTTPS address in Organisation settings. The server infers its single organisation at sign-in, so its identifier need not be compiled into the client. Credentials, account/grants and rotating refresh tokens are held only in platform secure storage. Startup restores that cache without network access, then attempts silent refresh; loss of connectivity does not erase local work or re-open sign-in.

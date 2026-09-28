# Backend runbook

One container serves one organisation. The device remains the store of record. This server holds accounts, membership and optional relay metadata. It does not hold project content.

## Deploy

Set `DATABASE_URL` and `TOKEN_SECRET` in the environment. Do not bake them into the image. Apply migrations with an explicit command before serving traffic:

```bash
npm run admin -- migrate
```

The process does not migrate on boot. Readiness stays failed until the pool connects and the secret store is present.

## Upgrade

Apply the next numbered migration forward only. A changed checksum or an out-of-order file refuses to run. Accounts, memberships and audit rows from the previous schema stay in place.

## Rotate a key

Replace `TOKEN_SECRET` and restart. Existing access tokens stop verifying. Users sign in again. Provider keys live in the key holder, not in the database and not in the client.

## Change retention

Set `RETENTION_DAYS` between 1 and 90. A value above 90 refuses to boot. Project retention cannot exceed the organisation maximum or 90 days.

## A purge failed

Read the purge report: `deleted`, `bytesReclaimed`, `oldestAgeSeconds`, `failures`. A non-zero `failures` means rows were left behind. Fix the cause and run the job again. Do not delete audit rows.

## Restore

Restore accounts, devices, memberships, roles, audit and package metadata. Projects are not included in a backup. Captured records stay on the devices. An export says so in its README.

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

Build Flutter with `--dart-define=BACKEND_URL=https://your-server` to provide the organisation address. A self-hosted install can instead save that HTTPS address in Organisation settings. The server infers its single organisation at sign-in, so its identifier need not be compiled into the client. Credentials, account/grants and rotating refresh tokens are held only in platform secure storage. Startup restores that cache without network access, then attempts silent refresh; loss of connectivity does not erase local work or re-open sign-in.

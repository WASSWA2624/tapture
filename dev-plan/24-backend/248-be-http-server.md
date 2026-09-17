# 248 — HTTP server, middleware chain and limits

**Phase** 24 · The minimal backend  |  **Depends on** [247](247-be-logger.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The Express application with a fixed middleware order, the request identifier that threads through every layer, the
configured body and rate limits, and the liveness, readiness and version routes.

## Files

- `backend/src/server.ts` (new)
- `backend/src/routes/health.ts` (new)
- `backend/src/middleware/request_context.ts` (new)
- `backend/src/middleware/rate_limit.ts` (new)
- `backend/test/routes/health.test.ts` (new)
- `backend/test/middleware/request_context.test.ts` (new)
- `backend/test/middleware/rate_limit.test.ts` (new)

## Contract

```ts
export const ctx: AsyncLocalStorage<RequestContext>;

GET /health    GET /ready    GET /version
```

## Steps

1. Fix the chain order: request context, body limits, security headers, rate limiter, authentication, router, error
   handler.
2. Generate a request identifier at the edge, carry it through `ctx` across every async boundary, attach it to every
   log line and return it to the client.
3. `/health` reports process liveness only; `/ready` additionally checks the database pool and the secret store;
   `/version` returns the build and API version.
4. Apply a global limit plus stricter per-endpoint limits on authentication and relay upload, keyed by address and by
   account, with maximum body and package sizes taken from configuration.

## Constraints

- Limits are enforced by middleware, never by a route handler (BE-API-08); exceeding one returns 429 with a retry hint
  and a logged security event (BE-SEC-07).
- No plaintext listener; HSTS on (BE-SEC-01).
- Readiness is separate from liveness so a deployment takes no traffic before it can serve it (BE-OBS-06).

## Definition of done

- [ ] A deployment receives no traffic until readiness passes, and readiness fails when the database is absent.
- [ ] Every log line for one request shares one identifier, and the client receives it.
- [ ] Exceeding any configured limit returns 429 with a retry hint and records a security event.
- [ ] Tests: route tests for liveness, readiness and version; a test asserting context propagation across an async
      boundary; a rate-limit test per limited endpoint.

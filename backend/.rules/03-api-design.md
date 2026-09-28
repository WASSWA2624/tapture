# 03 — API design

## BE-API-01 — Small surface, on purpose

The endpoint list in specification section 74.2 is the whole API. Adding an endpoint requires a dev-plan task and a
reason the device cannot do it alone.

## BE-API-02 — Versioned from the first commit

Everything under `/api/v1`. A breaking change means `v2`, never a silent change of meaning.

## BE-API-03 — Resources are plural nouns

`/projects`, `/org/users`, `/projects/:id/members`. Verbs appear only for actions that are genuinely not a resource:
`/relay/ack`, `/auth/refresh`.

## BE-API-04 — Status codes mean what they say

200 success, 201 created with a `Location`, 204 no content, 400 validation, 401 unauthenticated, 403 unauthorised,
404 not found or not visible to this user, 409 conflict, 413 too large, 429 rate limited, 500 unexpected.

## BE-API-05 — One error envelope

```json
{
  "error": {
    "code": "RELAY_PACKAGE_EXPIRED",
    "message": "That package has been purged.",
    "details": {}
  }
}
```

The code is stable and machine-readable; the message is safe to show a user; details never contain internals.

## BE-API-06 — Pagination is cursor-based

`limit` and `cursor`, with `nextCursor` in the response. No offset pagination, no unbounded list endpoint.

## BE-API-07 — Writes are idempotent where they can be

Relay pushes and acknowledgements accept an idempotency key; replaying one is a no-op. A flaky field connection must
never create duplicates.

## BE-API-08 — Limits are explicit

Maximum body size, maximum package size and rate limits are configured, documented and enforced by middleware, not by
each route.

## BE-API-09 — Not found and not permitted look the same

A user who cannot see a project gets 404, not 403 — membership is not an oracle.

## BE-API-10 — The client tolerates version drift

Older and newer clients receive a clear version message and degrade to standalone behaviour rather than failing
obscurely.

## BE-API-11 — The specification is the contract

Contract tests run the OpenAPI document against the running server. A route that drifts from the document fails the
build.

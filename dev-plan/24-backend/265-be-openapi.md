# 265 — OpenAPI specification and contract tests

**Phase** 24 · The minimal backend  |  **Depends on** [257](257-be-users-api.md), [260](260-be-relay-ack.md), [263](263-be-ai-proxy.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The API document that is the contract between the app and the server, and the suite that runs it against the running
server so any drift fails the build.

## Files

- `backend/openapi.yaml` (new)
- `backend/test/contract/` (new)
- `backend/test/contract/fixtures/drifted_route.ts` (new)

## Steps

1. Describe every endpoint of §74.2: request and response schemas, every error code, every status, the pagination
   parameters and the configured limits.
2. Drive each documented operation against a booted server with a migrated database, asserting status, envelope and
   schema for both the success and the documented failure cases.
3. Ship the drift fixture: a route whose shape no longer matches the document, proving the suite fails on it.

## Constraints

- The document lives beside the code and changes in the same pull request as the route, its contract test and the client
  expectation (BE-STR-10, BE-FLOW-03).
- Version drift is documented behaviour: an older or newer client receives a clear version message rather than an obscure
  failure (BE-API-10).

## Definition of done

- [ ] The document and the server never disagree, because a test proves it on every run.
- [ ] A route changed without the document fails continuous integration, and the fixture proves it.
- [ ] Tests: the contract suite green against the running server and red against the drift fixture, reporting every
      mismatch with route and field rather than stopping at the first.

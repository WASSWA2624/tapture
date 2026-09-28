# 01 — Structure

_Applies to dev-plan phase 24._

## BE-STR-01 — The server lives in `backend/`

One deployable, one repository folder. It shares no code with `frontend/`; contracts are shared as a written API
specification and contract tests, not as a package.

## BE-STR-02 — Module layout is fixed

```text
backend/src/
├── routes/         HTTP surface: validate, call a service, respond
├── services/       business rules, one per capability
├── repositories/   the only place SQL exists
├── domain/         types, invariants, pure functions
├── middleware/     auth, rate limiting, request context
├── jobs/           scheduled work: purge, retention, metrics
├── config/         environment loading and validation
└── types/          shared DTOs and API types
```

## BE-STR-03 — Routes are thin

A route validates input, calls one service method and shapes the response. No business rule, no SQL, no provider call
in a route handler.

## BE-STR-04 — SQL lives in repositories only

No query text outside `repositories/`. Services depend on repository interfaces, so they can be tested without a
database.

## BE-STR-05 — Domain is pure

`domain/` imports no framework, no database client and no HTTP library. Retention arithmetic, version-vector
comparison and permission rules live here and are unit-tested in isolation.

## BE-STR-06 — One module per resource

`auth`, `users`, `projects`, `members`, `relay`, `ai`, `health`. A file that belongs to two modules belongs to
neither; extract it into `domain/`.

## BE-STR-07 — Configuration is loaded once, validated at boot

`config/` reads the environment, validates it against a schema and exports typed values. Nothing else reads
`process.env`. A missing or malformed variable stops the server at boot, not at the first request.

## BE-STR-08 — No circular imports

Enforced by lint. A cycle means a missing `domain/` type.

## BE-STR-09 — Files stay readable

Above roughly 300 lines, split by responsibility.

## BE-STR-10 — The API specification is part of the source

The OpenAPI document lives beside the code, is updated in the same change as the route, and is verified by contract
tests.

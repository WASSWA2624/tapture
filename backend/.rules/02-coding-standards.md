# 02 — Coding standards

## BE-CODE-01 — TypeScript, strict

`strict`, `noImplicitAny`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`. Warnings are errors in
continuous integration.

## BE-CODE-02 — `any` is banned

Use `unknown` and narrow it. A cast that cannot be justified in a comment is a defect. No non-null assertions.

## BE-CODE-03 — Naming

Types `PascalCase`, values `camelCase`, files `kebab-case.ts`, constants `SCREAMING_SNAKE_CASE` only for true
compile-time constants. Booleans read as predicates.

## BE-CODE-04 — Validate at every boundary

Every request body, query string, parameter and environment variable is parsed by a schema before use. A handler
receives typed, validated input or nothing.

## BE-CODE-05 — Errors are typed

A sealed error type with a code, a public message and an optional cause. Never throw a bare string. Never leak an
internal message or a stack trace to a client.

## BE-CODE-06 — Async discipline

`async` and `await` only, no promise chains. No floating promises. Every external call has a timeout. Every job is
cancellable.

## BE-CODE-07 — Immutability by default

DTOs are `readonly`. No mutation of a request object. Shared mutable state is a bug waiting for concurrency.

## BE-CODE-08 — Logging

No `console.log`. Use the structured logger with a level and a request identifier. See `08-observability.md` for what
may never be logged.

## BE-CODE-09 — No magic values

Timeouts, limits, retention windows and page sizes come from configuration, with documented defaults.

## BE-CODE-10 — Comments explain why

No commented-out code. A `TODO` carries a dev-plan task number.

## BE-CODE-11 — Formatting is automated

Prettier and ESLint run in the gate. Style is never discussed in review.

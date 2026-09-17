# 246 — Configuration loading and validation

**Phase** 24 · The minimal backend  |  **Depends on** [245](245-be-project-init.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The typed configuration module: it reads the environment once at boot, validates it against a schema, exports typed
values, and stops the process with a message naming the offending variable when anything is missing or malformed.

## Files

- `backend/src/config/index.ts` (new)
- `backend/src/config/schema.ts` (new)
- `backend/.eslintrc.cjs` (edit)
- `backend/test/config/config.test.ts` (new)

## Contract

```ts
export const config: AppConfig; // throws at import time on an invalid environment
```

## Steps

1. Declare every variable with its type, default, whether it is required and a one-line description: listener,
   database URL and pool sizes, token lifetimes, body and package size limits, rate limits, retention window, storage
   ceilings, AI budgets and provider selection, log level.
2. Export typed values only; add the lint rule that forbids `process.env` anywhere outside this module.

## Constraints

- Every timeout, limit, retention window and page size used elsewhere originates here with a documented default
  (BE-CODE-09, BE-DEP-02).
- Boot fails loudly rather than starting half-configured (BE-DEP-03); no secret is ever read from source or the
  database (BE-SEC-04).

## Definition of done

- [ ] A missing secret stops the process at boot with a message naming the variable.
- [ ] Nothing outside `config/` can read `process.env`, and lint proves it.
- [ ] Tests: unit tests over valid, missing and malformed environments, including a value past its permitted maximum.

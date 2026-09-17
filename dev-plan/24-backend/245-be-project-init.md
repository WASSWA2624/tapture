# 245 — Initialise the backend project and its gate

**Phase** 24 · The minimal backend  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The Node and TypeScript project in `backend/`, with strict compiler settings, the fixed module skeleton, and the one
`verify` command that runs the whole review gate. The server builds, starts, serves a health route and stops cleanly.

## Files

- `backend/package.json` (new)
- `backend/tsconfig.json` (new)
- `backend/.eslintrc.cjs` (new)
- `backend/.prettierrc` (new)
- `backend/src/{routes,services,repositories,domain,middleware,jobs,config,types}/index.ts` (new)
- `backend/scripts/verify.ts` (new)
- `backend/test/boot.test.ts` (new)
- `backend/test/tools/verify.test.ts` (new)

## Contract

```text
npm run dev | npm run build | npm run test | npm run verify
```

## Steps

1. Enable `strict`, `noImplicitAny`, `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`; warnings are errors
   in continuous integration.
2. Create the eight source directories of BE-STR-02, each with an index.
3. Configure lint rules that ban `any`, non-null assertions, floating promises, `console` statements and circular
   imports.
4. `scripts/verify.ts` runs format, lint, type check, unit, integration and contract stages plus the dependency
   advisory and secret scans, prints one summary table and exits non-zero when any stage fails.

## Constraints

- The module tree is exactly the one in BE-STR-02; no ninth directory, no file above roughly 300 lines (BE-STR-09).
- One command reproduces the gate and behaves identically locally and in continuous integration (BE-FLOW-02).

## Definition of done

- [ ] The project builds and starts, serving nothing but a health route.
- [ ] `npm run verify` exits non-zero when any single stage fails, and names which.
- [ ] Tests: `backend/test/boot.test.ts` asserts the process starts and shuts down cleanly;
      `backend/test/tools/verify.test.ts` asserts exit-code aggregation across stages.

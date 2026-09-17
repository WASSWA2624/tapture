# 247 — Structured logger, typed errors and the error envelope

**Phase** 24 · The minimal backend  |  **Depends on** [246](246-be-config.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The JSON logger with an unbypassable redaction list, the sealed error type every layer throws, and the middleware that
renders any error as the single documented response envelope.

## Files

- `backend/src/observability/logger.ts` (new)
- `backend/src/domain/errors.ts` (new)
- `backend/src/middleware/error_handler.ts` (new)
- `backend/test/observability/log_leak.test.ts` (new)
- `backend/test/middleware/error_handler.test.ts` (new)

## Contract

```ts
log.info(event: string, fields: Record<string, unknown>): void

class AppError extends Error { code: ErrorCode; status: number; publicMessage: string; details?: object }
```

## Steps

1. Emit one JSON line per event with timestamp, level, request identifier, route, user, device and outcome.
2. Redact before serialisation, not at the call site: provider keys, tokens, passwords, package bytes, captions,
   transcripts, field values, user-supplied file names and whole request bodies.
3. Give every `ErrorCode` a status from the BE-API-04 set, and render `{ error: { code, message, details } }` and
   nothing else.
4. Log the cause once, internally, with the request identifier; return only `publicMessage`, never an internal
   message, a stack or a database error string.

## Constraints

- The redaction list is BE-OBS-02 in full, and a field passed deliberately must not escape it.
- Errors are a sealed type with a code and a public message; never a bare string, never a leaked internal (BE-CODE-05).
- `debug` is off in production; `error` means actionable (BE-OBS-04).

## Definition of done

- [ ] No forbidden pattern reaches the output, even when passed deliberately as a log field.
- [ ] An unexpected exception returns a 500 envelope and logs the cause exactly once.
- [ ] Tests: a leak test drives representative payloads and scans the emitted lines (BE-TEST-10); unit tests over the
      envelope shape and the status mapping of every error code, asserting no internal detail appears in a response.

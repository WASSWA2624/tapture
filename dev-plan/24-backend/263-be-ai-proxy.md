# 263 — AI proxy endpoints, quotas and resilience

**Phase** 24 · The minimal backend  |  **Depends on** [255](255-be-auth-tokens.md), [262](262-be-ai-provider.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The pass-through endpoints that forward the device's request to the provider and return the response unchanged, the
server-side budgets that a modified client cannot bypass, the usage report that makes cost attributable, and the bounded
call behaviour that turns a failing provider into a queueable error instead of a hung field device.

## Files

- `backend/src/routes/ai.ts` (new)
- `backend/src/services/ai/quota.ts` (new)
- `backend/src/services/ai/resilience.ts` (new)
- `backend/test/routes/ai_proxy.test.ts` (new)
- `backend/test/services/ai_quota.test.ts` (new)
- `backend/test/services/ai_resilience.test.ts` (new)

## Contract

```ts
POST /api/v1/ai/extract   POST /api/v1/ai/ocr   POST /api/v1/ai/transcribe   POST /api/v1/ai/refine
GET  /api/v1/ai/usage?project=&from=&to=
```

## Steps

1. Forward what the device composed and return what the provider answered: no prompt rewriting, no injected
   instruction, no reinterpretation of a result, no silent model downgrade.
2. Stream or buffer within the configured size limit and persist nothing — not to disk, not to the database, not to a
   cache — beyond the life of the request.
3. Check the per-project and per-organisation budget, request count and daily cap before the provider call; record
   project, user, model, byte size, duration, outcome and cost after it, and serve `usage` from those rows.
4. Bound every call with a timeout, retry transient failures with backoff, and open a circuit breaker on sustained
   failure so the caller gets a typed, queueable error within the timeout.

## Constraints

- Payloads are never persisted and logs carry metadata only — never a caption, transcript, field value or image
  (BE-AI-02, BE-AI-03).
- Quotas are enforced here because here they cannot be bypassed by an edited client (BE-AI-05).
- The proxy never fabricates a result and is never assumed to be the only path; an unreachable proxy is the client's
  queue, not an error to swallow (BE-AI-08, BE-AI-10).

## Definition of done

- [ ] No image, audio or extracted text is written to disk, database or cache, and no log line contains payload content.
- [ ] A runaway client cannot exceed the organisation budget, because the limit is not on the client.
- [ ] A dead provider returns a typed, queueable error within the timeout rather than hanging a field device.
- [ ] Tests: route tests asserting nothing is persisted and that logging is metadata-only; quota tests below, at and
      above each limit; timeout, retry and breaker-transition tests against the fake provider.

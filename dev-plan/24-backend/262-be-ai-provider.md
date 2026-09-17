# 262 — AI provider abstraction and key custody

**Phase** 24 · The minimal backend  |  **Depends on** [246](246-be-config.md), [247](247-be-logger.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The single interface every provider implements, the fake that every test uses in place of one, and the key holder that
reads provider credentials from the secret store and gives no caller a way to read one back.

## Files

- `backend/src/services/ai/provider.ts` (new)
- `backend/src/services/ai/keys.ts` (new)
- `backend/test/fakes/fake_provider.ts` (new)
- `backend/test/services/provider_contract.test.ts` (new)
- `backend/test/services/key_custody.test.ts` (new)

## Contract

```ts
interface AiProvider { extract(req): Promise<Res>; ocr(req): Promise<Res>; transcribe(req): Promise<Res>; refine(req): Promise<Res> }
```

## Steps

1. Select the implementation by one configuration value; adding a provider adds a file and a value and touches no route.
2. The fake can succeed, fail, time out and return malformed output, so every failure path has a way to be tested
   (BE-TEST-06).
3. Read keys from the secret store at boot and hold them behind an accessor that returns a configured client, never the
   key itself; a key never appears in a response, a log line, an error message or an exported report.

## Constraints

- Keys live only here; this custody is the reason the proxy exists (BE-AI-01, BE-SEC-04).
- Providers sit behind one interface so a swap is one implementation and one configuration change (BE-AI-06).
- Key custody is security-relevant surface and needs a second reader (BE-SEC-11).

## Definition of done

- [ ] Adding a provider is one implementation and one configuration value, with no route change.
- [ ] A key cannot be retrieved through any endpoint, including error paths.
- [ ] Tests: a contract suite every implementation must pass, driven by the fake across success, failure, timeout and
      malformed output; a test scanning every route response and log line for key patterns.

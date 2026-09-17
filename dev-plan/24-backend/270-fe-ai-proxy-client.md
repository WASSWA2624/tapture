# 270 — App: route AI through the backend

**Phase** 24 · The minimal backend  |  **Depends on** [147](../13-processing/147-provider-registry.md), [263](263-be-ai-proxy.md), [267](267-fe-backend-config.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The proxy implementation of the existing `AiService`, made the default custody arrangement: the backend holds the keys,
the device holds none, and a fresh install performs extraction without a key ever being entered (§30.2, §73.1).

## Files

- `frontend/lib/core/ai/proxy_ai_service.dart` (new)
- `frontend/lib/core/ai/provider_registry.dart` (edit)
- `frontend/test/core/ai/proxy_ai_service_test.dart` (new)

## Steps

1. Implement the existing `AiService` interface against the proxy endpoints, queueing on failure exactly as the direct
   provider does.
2. Register it in `provider_registry.dart` as the default provider for every project, so a fresh install holds no key and
   needs none.
3. Keep the device-held key path as the administrator-permitted exception it now is: selectable per project and labelled
   as the lone-operator arrangement.
4. Surface the server's quota, budget and usage figures (§36) in the same counters the direct path already uses.

## Constraints

- No key is compiled in and by default no key is on the device; custody belongs to the backend (FE-SEC-02).
- The networking import stays in `core/ai/`; no feature calls either provider directly (FE-SEC-03, FE-STR-11).
- A failed proxy call queues and preserves the input; it never discards a photo, caption or typed value (FE-SIMP-09).

## Definition of done

- [ ] A fresh install performs AI extraction with no key ever entered on the device.
- [ ] Choosing the proxy or a device key changes no code in any feature that uses AI.
- [ ] No response, error path or log line can bring a provider key onto the device.
- [ ] Tests: the same interface suite the direct provider passes, run against the proxy with a fake server, including
      timeout, breaker-open and quota-exceeded responses queueing rather than failing the capture.

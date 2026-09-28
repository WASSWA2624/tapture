# 07 — AI proxy

_Implements specification section 73._

## BE-AI-01 — Keys live only here

Provider keys are held by the server in a secret store. No endpoint returns one, no log records one, no response
echoes one. This is the whole reason the proxy exists.

## BE-AI-02 — Payloads are not persisted

Images, audio and extracted text pass through and are gone. Nothing is written to disk, to the database or to a cache
beyond the life of the request.

## BE-AI-03 — Log metadata only

Project, user, model, byte size, duration, outcome and cost. Never a caption, a transcript, a field value or an image.

## BE-AI-04 — The proxy adds no meaning

It forwards the request the device composed and returns the provider's response. It does not rewrite prompts, inject
instructions, or reinterpret results — the device owns the contract with the model.

## BE-AI-05 — Quotas are enforced server-side

Per-project and per-organisation budgets, request counts and daily caps are enforced here, because here they cannot be
bypassed by an edited client.

## BE-AI-06 — Providers sit behind one interface

Adding or swapping a provider is one implementation and one configuration change, with no route change.

## BE-AI-07 — Timeouts, retries and a circuit breaker

Every provider call is bounded. Transient failures retry with backoff; a failing provider opens the breaker and
returns a clear, queueable error rather than hanging the field device.

## BE-AI-08 — Failure is transparent

A provider error is returned as a typed error the client can queue and retry. The proxy never fabricates a result and
never silently downgrades a model.

## BE-AI-09 — Usage is visible

An endpoint reports usage by project and period, so cost is attributable and a runaway is noticed the same day.

## BE-AI-10 — The device can still work without it

If the proxy is unreachable, the client queues. Nothing on the server may assume it is the only path.

# 029 — AI service interface

**Phase** 02 · Foundation services  |  **Depends on** [014](../01-orchestration/014-riverpod-test.md), [021](021-result-and-failures.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

`frontend/lib/core/ai/ai_service.dart` is the single abstraction every provider implements, so a provider can be
swapped and AI can be switched off without a feature noticing.

## Files

- `frontend/lib/core/ai/ai_service.dart` (new)

## Steps

1. Declare `readText`, `extractFields`, `refineText` and `transcribe`, each taking a typed request and returning a typed result inside a `Result`.
2. Include a null implementation whose every method returns unavailable, used whenever AI is disabled.

## Constraints

- No feature imports a provider SDK; networking for AI lives only under `core/ai/` (FE-SEC-03).
- Request types carry OCR text, transcripts and template labels as quoted data, never interpolated into an instruction string (FE-SEC-05).
- The interface takes no key: custody belongs to the organisation's backend by default (FE-SEC-02).

## Definition of done

- [x] Every AI call in the app goes through `AiService`; no feature references a provider SDK type.
- [x] The null implementation returns a `ProviderFailure` carrying a recovery action for all four methods.
- [x] Tests: `frontend/test/core/ai/ai_service_test.dart` holds the contract tests every implementation must pass, run against the null implementation.

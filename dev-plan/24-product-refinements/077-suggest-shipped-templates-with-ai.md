# 077 — Suggest shipped templates with AI

**Implementation step:** 24.52

**Phase** 24 · Product refinements  |  **Depends on** [024](../23-backend/024-minimal-backend.md), [076](076-resolve-project-capture-package-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Split from FBK0000161 by task 076's decision D12. Task 076 ranks the shipped library on the device: a typed
description finds the best-matching templates offline (`ShippedTemplateRanking`). The reporter also asked that AI
suggest the most suitable templates, in order of best match, from a description of the work.

That cannot run yet: production has no AI provider (`ProviderRegistry.keyless()` with no proxy in
`frontend/lib/main.dart`), `AiService` has no ranking call (`readText`, `extractFields`, `refineText`,
`transcribe`), and the backend's AI endpoints (specification §74.2) include no search. Once task 024 serves AI
through the backend proxy, add a "Suggest with AI" action to the shipped library that:

- sends only the typed description and the names, codes and record types of the top on-device matches, never
  project data (FE-SEC-03, FE-SEC-05);
- asks through the existing operation surface (a choice field over those candidates, as `TemplateAssist` does) or
  a new `/ai/rank` endpoint added to §74.2 in the same change;
- respects the offline switch, the project's AI setting and the daily budget, and is hidden when AI is unavailable;
- shows the model's order as a proposal the person can ignore (AI proposes; a person approves).

## Files

- `frontend/lib/features/templates/presentation/shipped_picker_screen.dart`
- `frontend/lib/core/ai/ai_service.dart`

## Definition of done

- [ ] With AI available, a description returns the candidates in the model's order, marked as a suggestion.
- [ ] Offline, with AI off or unavailable, the action is hidden and on-device ranking still works.
- [ ] Nothing but the description and catalogue text leaves the device.
- [ ] Tests: a fake `AiService` ranking, the hidden states, and the egress payload.

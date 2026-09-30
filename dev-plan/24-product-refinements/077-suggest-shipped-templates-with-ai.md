# 077 — Suggest shipped templates with AI

**Implementation step:** 24.52

**Phase** 24 · Product refinements  |  **Depends on** [024](../23-backend/024-minimal-backend.md), [076](076-resolve-project-capture-package-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

**Implementation started:** Yes

## Implement

Split from FBK0000161 by task 076's decision D12. Task 076 ranks the shipped library on the device: a typed
description finds the best-matching templates offline (`ShippedTemplateRanking`). The reporter also asked that AI
suggest the most suitable templates, in order of best match, from a description of the work.

Production uses the configured AI proxy through the existing `extractFields` operation, with choice fields over
the on-device candidate catalogue. The "Suggest with AI" action in the shipped library:

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

Verification 2026-09-30: candidate ranking/payload domain tests, 15 shipped-picker tests, the complete proposal/reordering widget case and four budget/reservation controller cases passed. The model order is labelled as a suggestion and never selects a template automatically. Availability is rechecked after durable budget reservation, so switching offline during that wait prevents egress and clears the busy state. Payloads contain only the entered description and bounded catalogue text, without project records, context or images.

- [x] With AI available, a description returns the candidates in the model's order, marked as a suggestion.
- [x] Offline, with AI off or unavailable, the action is hidden and on-device ranking still works.
- [x] Nothing but the description and catalogue text leaves the device.
- [x] Tests: a fake `AiService` ranking, the hidden states, and the egress payload.

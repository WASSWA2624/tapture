# 156 — Refine captions

**Phase** 13 · Processing  |  **Depends on** [029](../02-foundation/029-ai-service-interface.md), [055](../04-data-layer/055-photos-table.md), [131](../12-capture/131-voice-permission.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A cleaned caption written into its own column beside the raw one, produced on request or when the project enables
automatic refinement, carrying no fact the raw caption did not.

## Files

- `frontend/lib/features/processing/domain/caption_refinement.dart` (new)

## Steps

1. Refine only on explicit request or when the project setting is on.
2. Reject a refinement that introduces an identifier, quantity or date absent from the raw text: the refiner may
   reword, not add.

## Constraints

- Raw captions and transcripts are append-only; refinement writes a separate column and never edits the original
  row (FE-SEC-08).

## Definition of done

- [ ] Raw and refined are both retrievable and both exportable.
- [ ] Tests: unit tests asserting the raw row is unchanged and that a refinement introducing a new fact is rejected.

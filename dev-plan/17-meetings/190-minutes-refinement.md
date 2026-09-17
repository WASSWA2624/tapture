# 190 — Refine the minutes

**Phase** 17 · Meetings  |  **Depends on** [156](../13-processing/156-caption-refinement.md), [189](189-meeting-audio.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

On request, turn the raw notes and the transcript into structured minutes — a summary per agenda item, a list of
decisions, and actions with owners and dates — shown beside the raw material, both sides editable.

## Files

- `frontend/lib/features/meetings/domain/minutes_refinement.dart` (new)

## Steps

1. Produce a discussion summary per agenda item, plus decisions and actions carrying the owner and due date the
   material states.
2. Reject any attendee, decision or action with no support in the raw notes or transcript, naming the offending item.
3. Show raw notes and refined minutes side by side, both editable; refining again adds a version rather than
   overwriting one.

## Definition of done

- [ ] A fabricated action is rejected by the guard, and the rejection names the item.
- [ ] Raw notes and refined minutes are shown side by side and both are editable.
- [ ] Tests: unit tests of `minutes_refinement.dart` asserting a fabricated action is rejected, a supported one
      survives, and the raw material is unchanged by refinement, with no Flutter binding.

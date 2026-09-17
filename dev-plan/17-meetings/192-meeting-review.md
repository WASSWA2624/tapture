# 192 — Meeting review and approval

**Phase** 17 · Meetings  |  **Depends on** [184](../16-review/184-approve-record.md), [190](190-minutes-refinement.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A meeting is reviewed and approved down the same path as any other record, with the meeting-specific completeness
checks standing in front of export.

## Files

- `frontend/lib/features/meetings/presentation/meeting_review_screen.dart` (new)

## Steps

1. Approve through the action of 342; this screen adds the meeting summary above it — attendance count, decisions and
   actions — rather than a second approval path.
2. Where the template requires it, block approval while an action has no owner or no due date, naming the action.

## Definition of done

- [ ] A meeting cannot be exported while its actions have no owners, when the template requires them.
- [ ] Approving a meeting writes the same lifecycle and audit trail as any other record.
- [ ] Tests: widget test of `meeting_review_screen.dart` covering a complete meeting, an ownerless action blocking
      approval, and its empty and failure states.

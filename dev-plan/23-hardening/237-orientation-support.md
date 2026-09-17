# 237 — Landscape and foldables

**Phase** 23 · Hardening  |  **Depends on** [236](236-responsive-audit.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Capture and review work in landscape, and a hinged display splits the two-pane layout at the fold. Rotating, folding or
unfolding never costs the operator an in-progress capture.

## Files

- `frontend/lib/app/nav_shell.dart` (edit)

## Steps

1. Navigation adapts to the size class while state stays owned by its providers, so a rotation rebuilds the chrome and
   nothing else (FE-RESP-03).
2. When a display feature reports a hinge, place list and detail either side of it rather than letting content sit
   under the fold.
3. Preserve the in-progress capture across every configuration change: draft field values, queued photos, an active
   recording and scroll position.

## Constraints

- Both orientations are supported on every screen; no screen locks rotation (FE-RESP-07).
- Insets and cutouts are respected in landscape, where they bite hardest (FE-RESP-08).

## Definition of done

- [ ] Rotating or folding during capture keeps the draft record, the queued photos and any active recording.
- [ ] Tests: widget tests of `nav_shell.dart` rotating and simulating a hinge mid-capture, asserting draft values,
      queued photos and recording state survive, and that the two-pane split follows the hinge.

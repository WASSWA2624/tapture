# 073 — Keep resumed capture photos

**Phase** 23 · Hardening  |  **Depends on** [070](070-resolve-web-capture-caption-template-feedback.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Found while checking task 070 in a browser. When the Capture page opens, its first frames schedule
`CaptureController.setTemplate` and `setContext` for the fresh session. Each builds its next session from `state`
as it was when called, awaits `saveSession`, and only then assigns it. If the operator taps Resume on the recovery
prompt while those saves are still in flight, `replaceSession` sets the resumed session, and the late
`setTemplate` or `setContext` then assigns and stores the fresh, photo-less session over it. The tray shows no
photos and the stored draft loses them; the photo rows and files stay, unlinked from any session. A browser's
database writes are slow enough to hit this every time Resume is tapped within a few seconds of opening Capture;
a device can hit it too.

Make every session change apply to the session current when its write lands, never to a stale copy, so no change
can undo another; a resumed session keeps its photos, captions and audio.

## Files

- `frontend/lib/features/capture/presentation/capture_controller.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`

## Definition of done

- [ ] Resume tapped while the template and context writes are still in flight keeps every resumed photo, caption
      and audio clip, in the tray and in the stored session.
- [ ] Concurrent caption, value, template and context changes each land, whatever order their writes finish in.
- [ ] Tests: controller tests with a session store whose writes finish out of order, and a capture screen test that
      resumes during slow writes.

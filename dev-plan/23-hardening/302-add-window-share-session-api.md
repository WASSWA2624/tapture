# 302 — Add a window share session to screen capture

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Replace the one-shot display picker with a session: one `start`, any
number of `still`s, then `stop`. Give us feedback still takes one still
and stops at once.

## Files

- `frontend/lib/core/files/screen_capture.dart`
- `frontend/lib/core/files/screen_capture_web.dart`
- `frontend/lib/core/files/screen_capture_io.dart`
- `frontend/lib/core/files/screen_capture_stub.dart`
- `frontend/lib/features/feedback/presentation/give_feedback_controller.dart`
- `frontend/test/core/files/screen_capture_test.dart`

## Constraints

- Display APIs stay in this core service, with a fake (FE-STR-11).
- `dart:js_interop` only; no new package (FE-FLOW-06).
- Stills only on an explicit call; no frame data in logs (FE-SEC-07,
  FE-SEC-10, FE-CODE-08).
- Public methods return `Result`; no raw exception crosses the boundary
  (FE-CODE-06). Awaited promises use the camera-ready timeout (FE-CODE-07).
- `stop` removes the video and the `ended` listener (FE-STATE-09).
- Do not change shot controls, copy, camera, library, or the workbook.

## Definition of done

- [x] One `start` and three `still`s return three PNGs from one picker.
- [x] After `stop` or the browser's Stop sharing, `isSharing` is false and
      `ended` has fired.
- [x] Give us feedback still adds one still per tap and leaves no stream.
- [x] Native `canCapture` is false and `start` returns false.
- [x] Tests: successive frames; cancel; refusal; `stop` fires `ended`;
      native hidden.

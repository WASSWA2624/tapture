# 122 — Camera permission and preview

**Phase** 12 · Capture  |  **Depends on** [005](../01-orchestration/005-dependency-allowlist.md), [026](../02-foundation/026-permissions-service.md), [121](121-capture-screen.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The gate that asks for the camera once, explains why on screen, and degrades to gallery import and typed capture on
refusal; and the preview it reveals — correctly oriented, aspect-correct, released on background and restored without
a black frame.

## Files

- `frontend/lib/features/capture/presentation/camera_permission_gate.dart` (new)
- `frontend/lib/features/capture/presentation/camera_view.dart` (new)

## Steps

1. Ask at the moment the camera is first needed, never at launch, with the reason visible before the system prompt.
2. On refusal keep gallery import and typed capture reachable, and offer a route to system settings when the refusal
   is permanent.
3. Size the preview from the controller's reported preview size; handle rotation in both orientations.
4. Release the camera surface on pause and rebuild it on resume.

## Constraints

- Camera and permissions are reached only through their `core/` services, each with a fake (FE-STR-11).
- The camera plugin is on the dependency allowlist checked by task 005.
- Preview state models starting, running and failed, and renders all three (FE-STATE-11).

## Definition of done

- [ ] A user who denies the camera can still add evidence and save a record.
- [ ] Returning from background restores the preview without a black frame, in both orientations.
- [ ] Tests: widget test of `camera_permission_gate.dart` covering granted, denied and permanently denied; widget test of `camera_view.dart` covering starting, running, failed and a pause-resume cycle, against a fake camera service.

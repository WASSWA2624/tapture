# 120 — Capture session model and controller

**Phase** 12 · Capture  |  **Depends on** [014](../01-orchestration/014-riverpod-test.md), [023](../02-foundation/023-clock-service.md), [054](../04-data-layer/054-records-table.md), [055](../04-data-layer/055-photos-table.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The in-progress session that holds photos, captions and typed values before and after the first save, and the
controller that owns it and writes every addition through to disk and the database as it happens rather than on save.

## Files

- `frontend/lib/features/capture/domain/capture_session.dart` (new)
- `frontend/lib/features/capture/presentation/capture_controller.dart` (new)

## Contract

```dart
class CaptureSession {
  const CaptureSession({
    required this.id,
    required this.templateId,
    required this.contextSnapshot,
    this.recordId,
    this.photos = const [],
    this.captions = const {},
    this.values = const {},
    this.isDirty = false,
  });
  final String id;
  Map<String, Object?> toJson();
  static CaptureSession fromJson(Map<String, Object?> json);
  CaptureSession copyWith({...});
}

// Intent methods, the only way the session changes.
abstract class CaptureController {
  Future<void> addPhoto(PhotoDraft photo);
  Future<void> removePhoto(String photoId);
  Future<void> reorderPhotos(List<String> orderedIds);
  Future<void> setCaption(String? photoId, String text);
  Future<void> setValue(String fieldKey, Object? value);
}
```

## Steps

1. Model session id, template, context snapshot, photo list, captions, field values, record id and dirty state.
2. Every mutation is a method on the controller; widgets never rebuild the model themselves.
3. Persist each addition before the notifier emits its next state, so the emitted state is always already durable.
4. Serialise the session so an interrupted run can be found and restored.

## Constraints

- Writes, hashing and encoding run off the UI thread through the isolate runner and the file writer (FE-PERF-02).
- The session is the single source of truth for the photo list; no second provider mirrors it (FE-STATE-06).
- Photos, captions and transcripts are written once; corrections write beside them (FE-SEC-08).

## Definition of done

- [ ] Killing the app mid-session loses at most the last keystroke.
- [ ] A session serialises, restores and resumes with its photos, captions and values intact.
- [ ] Tests: unit tests of every mutation and of the JSON round trip; controller test asserting a photo added is on disk and in the database before the next frame, and that a failed write leaves the emitted state unchanged.

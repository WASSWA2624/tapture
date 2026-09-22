import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

void main() {
  test('JSON round trip keeps photos captions values', () {
    const CaptureSession session = CaptureSession(
      id: 's1',
      projectId: 'p1',
      templateId: 't1',
      contextSnapshot: <String, String>{'site': 'A'},
      photos: <PhotoDraft>[
        PhotoDraft(
          id: 'ph1',
          projectId: 'p1',
          relativePath: 'photos/a.jpg',
          sha256: 'abc',
          photoType: 'front',
        ),
      ],
      captions: <String, String>{'': 'hello', 'ph1': 'plate'},
      values: <String, Object?>{'serial': '42'},
      isDirty: true,
    );
    final CaptureSession restored = CaptureSession.fromJson(session.toJson());
    expect(restored.id, 's1');
    expect(restored.photos, hasLength(1));
    expect(restored.photos.first.photoType, 'front');
    expect(restored.captions[''], 'hello');
    expect(restored.values['serial'], '42');
    expect(restored.contextSnapshot['site'], 'A');
    expect(restored.isDirty, isTrue);
  });
}

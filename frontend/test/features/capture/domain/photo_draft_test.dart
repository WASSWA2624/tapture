import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

void main() {
  test('recovery JSON and copy preserve complete original metadata', () {
    final DateTime capturedAt = DateTime.utc(2026, 9, 23, 16, 35);
    final PhotoDraft original = PhotoDraft(
      id: 'photo-1',
      projectId: 'project-1',
      recordId: 'record-1',
      captureSessionId: 'session-1',
      storedFilename: 'photo-1.jpg',
      relativePath: 'photos/photo-1.jpg',
      sha256: 'abc123',
      photoType: 'serial',
      sortOrder: 2,
      originalFilename: 'IMG_0001.JPG',
      width: 1920,
      height: 1080,
      fileSize: 4096,
      capturedAt: capturedAt,
      gpsLat: 0.3476,
      gpsLon: 32.5825,
      rotationDegrees: 90,
      hasCaption: true,
      derivedFrom: 'photo-0',
    );

    final PhotoDraft restored = PhotoDraft.fromJson(original.toJson());
    final PhotoDraft cleared = restored.copyWith(clearRecordId: true);

    expect(restored.toJson(), original.toJson());
    expect(restored.asAsset.recordId, 'record-1');
    expect(cleared.recordId, isNull);
    expect(cleared.sha256, original.sha256);
    expect(cleared.capturedAt, capturedAt);
  });
}

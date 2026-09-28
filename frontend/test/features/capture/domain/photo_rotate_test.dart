import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_rotate.dart';

const PhotoDraft _photo = PhotoDraft(
  id: '1',
  projectId: 'p',
  relativePath: 'photos/a.jpg',
  sha256: 'abc123',
  photoType: 'front',
  sortOrder: 3,
  fileSize: 2048,
  hasCaption: true,
);

/// Everything about [photo] except its rotation.
Map<String, Object?> _bytesAndMetadata(PhotoDraft photo) {
  return photo.toJson()..remove('rotationDegrees');
}

void main() {
  test('a quarter turn is stored as metadata and the file is untouched', () {
    final PhotoDraft rotated = PhotoRotate.apply(_photo, 90);

    expect(rotated.rotationDegrees, 90);
    expect(rotated.sha256, _photo.sha256);
    expect(rotated.relativePath, _photo.relativePath);
    expect(_bytesAndMetadata(rotated), _bytesAndMetadata(_photo));
  });

  test('turns accumulate and wrap back to the original orientation', () {
    PhotoDraft photo = _photo;
    final List<int> seen = <int>[];
    for (var turn = 0; turn < 4; turn++) {
      photo = PhotoRotate.apply(photo, 90);
      seen.add(photo.rotationDegrees);
    }

    expect(seen, <int>[90, 180, 270, 0]);
  });

  test('a negative turn goes the other way', () {
    expect(PhotoRotate.apply(_photo, -90).rotationDegrees, 270);
    expect(PhotoRotate.apply(_photo, -180).rotationDegrees, 180);
  });

  test('a full turn or more is reduced to one orientation', () {
    expect(PhotoRotate.apply(_photo, 360).rotationDegrees, 0);
    expect(PhotoRotate.apply(_photo, 450).rotationDegrees, 90);
    expect(PhotoRotate.apply(_photo, -450).rotationDegrees, 270);
  });

  test('an odd angle snaps to the nearest quarter turn', () {
    expect(PhotoRotate.apply(_photo, 40).rotationDegrees, 0);
    expect(PhotoRotate.apply(_photo, 100).rotationDegrees, 90);
    expect(PhotoRotate.apply(_photo, 260).rotationDegrees, 270);
  });

  test('revert restores the original orientation and nothing else', () {
    final PhotoDraft turned = PhotoRotate.apply(_photo, 270);

    final PhotoDraft reverted = PhotoRotate.revert(turned);

    expect(reverted.rotationDegrees, 0);
    expect(_bytesAndMetadata(reverted), _bytesAndMetadata(_photo));
  });

  test('the draft handed in is never mutated', () {
    final PhotoDraft rotated = PhotoRotate.apply(_photo, 90);

    expect(identical(rotated, _photo), isFalse);
    expect(_photo.rotationDegrees, 0);
  });
}

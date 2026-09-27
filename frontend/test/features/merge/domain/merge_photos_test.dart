import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/merge_photos.dart';

void main() {
  test('the same photo is one file and both captions are kept', () {
    final List<MergedPhoto> photos = MergePhotos.union(
      local: const <PhotoSide>[
        (sha256: 'abc', path: 'photos/a.jpg', caption: 'Here'),
      ],
      incoming: const <PhotoSide>[
        (sha256: 'abc', path: 'photos/b.jpg', caption: 'There'),
        (sha256: 'def', path: 'photos/c.jpg', caption: 'New'),
      ],
    );
    expect(photos, hasLength(2));
    expect(photos.first.path, 'photos/a.jpg');
    expect(photos.first.captions, <String>['Here', 'There']);
  });
}

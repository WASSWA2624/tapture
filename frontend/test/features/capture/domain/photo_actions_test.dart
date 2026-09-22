import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/photo_move_action.dart';
import 'package:tapture/features/capture/presentation/photo_retake_action.dart';

void main() {
  test('retake preserves position and metadata', () {
    final List<PhotoDraft> photos = <PhotoDraft>[
      const PhotoDraft(
        id: 'a',
        projectId: 'p',
        relativePath: 'a.jpg',
        sha256: '1',
        photoType: 'front',
        sortOrder: 0,
        hasCaption: true,
      ),
      const PhotoDraft(
        id: 'b',
        projectId: 'p',
        relativePath: 'b.jpg',
        sha256: '2',
        sortOrder: 1,
      ),
    ];
    final List<PhotoDraft> next = PhotoRetakeAction.visibleTray(
      photos: photos,
      oldId: 'a',
      replacement: const PhotoDraft(
        id: 'c',
        projectId: 'p',
        relativePath: 'c.jpg',
        sha256: '3',
      ),
    );
    expect(next.first.id, 'c');
    expect(next.first.photoType, 'front');
    expect(next.first.hasCaption, isTrue);
    expect(next.first.sortOrder, 0);
  });

  test('move rolls back on failure', () async {
    final List<PhotoDraft> photos = <PhotoDraft>[
      const PhotoDraft(
        id: 'a',
        projectId: 'p',
        relativePath: 'a.jpg',
        sha256: '1',
      ),
      const PhotoDraft(
        id: 'b',
        projectId: 'p',
        relativePath: 'b.jpg',
        sha256: '2',
      ),
    ];
    var writes = 0;
    final Result<List<PhotoDraft>> result = await PhotoMoveAction.run(
      photos: photos,
      photoIds: <String>{'a', 'b'},
      targetRecordId: 'r2',
      write: (PhotoDraft photo) async {
        writes++;
        if (writes == 2) {
          return const FailureResult<PhotoDraft>(
            StorageFailure(message: 'fail', recoveryAction: 'retry'),
          );
        }
        return Success<PhotoDraft>(photo);
      },
      rollback: (PhotoDraft _) async => const Success<void>(null),
    );
    expect(result, isA<FailureResult<List<PhotoDraft>>>());
  });
}

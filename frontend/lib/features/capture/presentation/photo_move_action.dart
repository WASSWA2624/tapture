import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

/// Relocates selected photos to another record in one transaction.
abstract final class PhotoMoveAction {
  /// Moves [photoIds] onto [targetRecordId]. On mid-move failure rolls back.
  static Future<Result<List<PhotoDraft>>> run({
    required List<PhotoDraft> photos,
    required Set<String> photoIds,
    required String targetRecordId,
    required Future<Result<PhotoDraft>> Function(PhotoDraft photo) write,
    required Future<Result<void>> Function(PhotoDraft photo) rollback,
  }) async {
    final List<PhotoDraft> moved = <PhotoDraft>[];
    final List<PhotoDraft> previous = <PhotoDraft>[];
    for (final PhotoDraft photo in photos) {
      if (!photoIds.contains(photo.id)) {
        continue;
      }
      previous.add(photo);
      final PhotoDraft next = photo.copyWith(recordId: targetRecordId);
      final Result<PhotoDraft> saved = await write(next);
      final Failure? fail = saved.fold((Failure f) => f, (_) => null);
      if (fail != null) {
        for (final PhotoDraft prior in previous) {
          await rollback(prior);
        }
        return FailureResult<List<PhotoDraft>>(fail);
      }
      moved.add(saved.getOrElse(() => next));
    }
    return Success<List<PhotoDraft>>(moved);
  }
}

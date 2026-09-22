import 'package:tapture/features/capture/domain/photo_draft.dart';

/// Retake keeps the old file superseded and places the new photo at the
/// same position with the same type and caption.
abstract final class PhotoRetakeAction {
  /// Merges [replacement] into [photos] at the index of [oldId].
  static List<PhotoDraft> apply({
    required List<PhotoDraft> photos,
    required String oldId,
    required PhotoDraft replacement,
  }) {
    final List<PhotoDraft> next = <PhotoDraft>[];
    for (final PhotoDraft photo in photos) {
      if (photo.id == oldId) {
        next.add(
          replacement.copyWith(
            sortOrder: photo.sortOrder,
            photoType: photo.photoType,
            hasCaption: photo.hasCaption,
          ),
        );
        next.add(photo.copyWith(supersededBy: replacement.id));
      } else if (photo.supersededBy != oldId) {
        next.add(photo);
      }
    }
    // Keep tray order: replacement at old position, superseded excluded from
    // the visible tray by callers that filter supersededBy != null on others.
    return next
        .where(
          (PhotoDraft p) => p.supersededBy == null || p.id == replacement.id,
        )
        .toList();
  }

  /// Visible tray after retake — replacement only at the old index.
  static List<PhotoDraft> visibleTray({
    required List<PhotoDraft> photos,
    required String oldId,
    required PhotoDraft replacement,
  }) {
    return <PhotoDraft>[
      for (final PhotoDraft photo in photos)
        if (photo.id == oldId)
          replacement.copyWith(
            sortOrder: photo.sortOrder,
            photoType: photo.photoType,
            hasCaption: photo.hasCaption,
          )
        else if (photo.supersededBy == null)
          photo,
    ];
  }
}

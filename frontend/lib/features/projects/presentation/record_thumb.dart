import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';

import '../domain/project_repository.dart';

/// A stored photo's cached thumbnail, turned the way it was saved. Blank
/// while the thumbnail loads; Missing photo when the file is gone.
class RecordThumb extends ConsumerWidget {
  /// Creates the thumbnail for [photo] at [size].
  const RecordThumb({
    required this.photo,
    this.size = Space.x12,
    this.hasCaption = false,
    super.key,
  });

  /// Photo to show.
  final RecordPhotoRef photo;

  /// Layout edge.
  final double size;

  /// Whether the caption mark shows.
  final bool hasCaption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String?> path = ref.watch(recordThumbnailProvider(photo));
    final String thumbPath = switch (path) {
      AsyncData<String?>(:final String? value) => value ?? _missingThumb,
      AsyncError<String?>() => _missingThumb,
      _ => '',
    };
    return AppPhotoThumb(
      photo: PhotoAsset(
        sha256: photo.sha256,
        thumbPath: thumbPath,
        hasCaption: hasCaption,
      ),
      quarterTurns: photo.quarterTurns,
      size: size,
    );
  }
}

/// Cached thumbnail path for a stored photo, or null when it cannot be made.
final recordThumbnailProvider = FutureProvider.autoDispose
    .family<String?, RecordPhotoRef>((Ref ref, RecordPhotoRef photo) async {
      final Result<String> path = await ref
          .watch(photoThumbnailsProvider)
          .pathFor(
            sha256: photo.sha256,
            storagePath: photo.storagePath,
            edge: AppConstants.images.thumbnailEdge,
          );
      return switch (path) {
        Success<String>(:final String value) => value,
        FailureResult<String>() => null,
      };
    }, retry: (int _, Object _) => null);

/// A path that never exists, so [AppPhotoThumb] draws Missing photo, as
/// the capture tray does.
const String _missingThumb = 'missing';

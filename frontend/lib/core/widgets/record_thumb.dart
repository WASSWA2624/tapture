import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_thumbnails.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';

/// A stored photo's cached thumbnail, turned the way it was saved: the one
/// thumbnail record rows, the record page and project cover photos share
/// (FE-CONS-02, FE-STR-09).
///
/// It draws [AppPhotoThumb] from the cached thumbnail at
/// [AppConstants.images] `thumbnailEdge`, never the original (FE-PERF-04).
/// Blank while the thumbnail loads; Missing photo when the file is gone or
/// cannot be read. Tap opens and long-press selects (FE-CONS-10).
class RecordThumb extends ConsumerWidget {
  /// Creates the thumbnail for the photo stored at [storagePath], relative to
  /// the storage root, whose content hash is [sha256].
  const RecordThumb({
    required this.sha256,
    required this.storagePath,
    this.quarterTurns = 0,
    this.size = Space.x12,
    this.hasCaption = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    super.key,
  });

  /// Content hash of the photo, which keys its cached thumbnail.
  final String sha256;

  /// Path of the photo file under the storage root. Only the thumbnail
  /// service reads it; this widget never decodes it.
  final String storagePath;

  /// Clockwise quarter turns of the saved rotation.
  final int quarterTurns;

  /// Layout edge of the square. Anything under 48dp still takes a 48dp
  /// target (FE-A11Y-01).
  final double size;

  /// Whether the caption mark shows.
  final bool hasCaption;

  /// Multi-select highlight, a tick as well as a border (FE-A11Y-05).
  final bool selected;

  /// Opens the photo, for example in the viewer. Null means not tappable.
  final VoidCallback? onTap;

  /// Starts multi-select. Null means long-press does nothing.
  final VoidCallback? onLongPress;

  /// What a screen reader calls the photo, in place of "Photo". The missing,
  /// captioned and selected states are still read after it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String?> path = ref.watch(
      _thumbPathProvider((sha256: sha256, storagePath: storagePath)),
    );
    final String thumbPath = switch (path) {
      AsyncData<String?>(:final String? value) => value ?? _missingThumb,
      AsyncError<String?>() => _missingThumb,
      _ => '',
    };
    return AppPhotoThumb(
      photo: PhotoAsset(
        sha256: sha256,
        thumbPath: thumbPath,
        hasCaption: hasCaption,
      ),
      quarterTurns: quarterTurns,
      size: size,
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
    );
  }
}

/// Which stored photo a thumbnail is for. The rotation is left out: every
/// turn of one photo shares one cached thumbnail.
typedef _ThumbSource = ({String sha256, String storagePath});

/// Cached thumbnail path for a stored photo, or null when it cannot be made.
final _thumbPathProvider = FutureProvider.autoDispose
    .family<String?, _ThumbSource>((Ref ref, _ThumbSource photo) async {
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

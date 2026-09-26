part of 'app_photo_thumb.dart';

/// A photograph kept as evidence. Lives here until the capture-session and
/// photos-table tasks own the domain type; core cannot import features
/// (FE-STR-04).
@immutable
class PhotoAsset {
  /// Creates a photo. [thumbPath] is the cached file for the requested
  /// edge; [sourcePath] is the original and is never decoded by
  /// [AppPhotoThumb] (FE-PERF-04). [thumbBytes] stands in for a cached file
  /// where there is no file system, as in a browser.
  const PhotoAsset({
    required this.sha256,
    this.thumbPath = '',
    this.sourcePath = '',
    this.thumbBytes,
    this.photoType,
    this.hasCaption = false,
  });

  /// Content hash. Cache keys are `<sha256>_<edge>`.
  final String sha256;

  /// Cached thumbnail path for the requested size. Empty until the cache
  /// has resolved a file.
  final String thumbPath;

  /// Original photo path. [AppPhotoThumb] never opens this file.
  final String sourcePath;

  /// The photo's encoded bytes, drawn when set in place of [thumbPath] and
  /// decoded at the thumbnail's size, never at full size (FE-PERF-04). A
  /// browser has no cached thumbnail files, so its capture tray passes
  /// these. Compared by identity.
  final Uint8List? thumbBytes;

  /// Optional type badge. Null hides the badge.
  final PhotoType? photoType;

  /// When true, the caption indicator is shown.
  final bool hasCaption;

  /// Disk key used under `.cache/thumbs/`: `<sha256>_<edge>`.
  String cacheKey(int edge) => '${sha256}_$edge';

  @override
  bool operator ==(Object other) {
    return other is PhotoAsset &&
        other.sha256 == sha256 &&
        other.thumbPath == thumbPath &&
        other.sourcePath == sourcePath &&
        identical(other.thumbBytes, thumbBytes) &&
        other.photoType == photoType &&
        other.hasCaption == hasCaption;
  }

  @override
  int get hashCode {
    return Object.hash(
      sha256,
      thumbPath,
      sourcePath,
      identityHashCode(thumbBytes),
      photoType,
      hasCaption,
    );
  }
}

/// Closed set of photo types from the specification, used for the type
/// badge, file naming and evidence tracking.
enum PhotoType {
  /// Facing the subject.
  front,

  /// Reverse of the subject.
  back,

  /// Serial number plate or stamp.
  serial,

  /// Manufacturer rating plate.
  ratingPlate,

  /// Visible damage.
  damage,

  /// Control or breaker panel.
  panel,

  /// Site or room context.
  location,

  /// People present at a meeting.
  attendance,

  /// A page or scanned document.
  document,

  /// Anything else.
  other;

  /// Semantic and tray label.
  String get label {
    return switch (this) {
      PhotoType.front => Copy.photoFront,
      PhotoType.back => Copy.photoBack,
      PhotoType.serial => Copy.photoSerial,
      PhotoType.ratingPlate => Copy.photoRatingPlate,
      PhotoType.damage => Copy.photoDamage,
      PhotoType.panel => Copy.photoPanel,
      PhotoType.location => Copy.photoLocation,
      PhotoType.attendance => Copy.photoAttendance,
      PhotoType.document => Copy.photoDocument,
      PhotoType.other => Copy.photoOther,
    };
  }

  /// Short overlay text that fits a corner without covering the subject.
  String get badgeLabel {
    return switch (this) {
      PhotoType.ratingPlate => Copy.photoRatingPlateBadge,
      PhotoType.attendance => Copy.photoAttendanceBadge,
      PhotoType.document => Copy.photoDocumentBadge,
      _ => label,
    };
  }

  /// Glyph shown with [badgeLabel] so colour is never the only signal.
  IconData get icon {
    return switch (this) {
      PhotoType.front => AppIcons.photoFront,
      PhotoType.back => AppIcons.photoBack,
      PhotoType.serial => AppIcons.photoSerial,
      PhotoType.ratingPlate => AppIcons.photoRatingPlate,
      PhotoType.damage => AppIcons.photoDamage,
      PhotoType.panel => AppIcons.photoPanel,
      PhotoType.location => AppIcons.photoLocation,
      PhotoType.attendance => AppIcons.photoAttendance,
      PhotoType.document => AppIcons.photoDocument,
      PhotoType.other => AppIcons.photoOther,
    };
  }
}

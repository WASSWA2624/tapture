part of 'app_photo_thumb.dart';

/// A photograph kept as evidence. Lives here until the capture-session and
/// photos-table tasks own the domain type; core cannot import features
/// (FE-STR-04).
@immutable
class PhotoAsset {
  /// Creates a photo. [thumbPath] is the cached file for the requested
  /// edge; [sourcePath] is the original and is never decoded by
  /// [AppPhotoThumb] (FE-PERF-04).
  const PhotoAsset({
    required this.sha256,
    this.thumbPath = '',
    this.sourcePath = '',
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
        other.photoType == photoType &&
        other.hasCaption == hasCaption;
  }

  @override
  int get hashCode {
    return Object.hash(sha256, thumbPath, sourcePath, photoType, hasCaption);
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
      PhotoType.front => 'Front',
      PhotoType.back => 'Back',
      PhotoType.serial => 'Serial',
      PhotoType.ratingPlate => 'Rating plate',
      PhotoType.damage => 'Damage',
      PhotoType.panel => 'Panel',
      PhotoType.location => 'Location',
      PhotoType.attendance => 'Attendance',
      PhotoType.document => 'Document',
      PhotoType.other => 'Other',
    };
  }

  /// Short overlay text that fits a corner without covering the subject.
  String get badgeLabel {
    return switch (this) {
      PhotoType.ratingPlate => 'Plate',
      PhotoType.attendance => 'Attend',
      PhotoType.document => 'Doc',
      _ => label,
    };
  }

  /// Glyph shown with [badgeLabel] so colour is never the only signal.
  IconData get icon {
    return switch (this) {
      PhotoType.front => Icons.crop_portrait,
      PhotoType.back => Icons.flip_to_back,
      PhotoType.serial => Icons.pin_outlined,
      PhotoType.ratingPlate => Icons.badge_outlined,
      PhotoType.damage => Icons.report_outlined,
      PhotoType.panel => Icons.grid_view_outlined,
      PhotoType.location => Icons.place_outlined,
      PhotoType.attendance => Icons.groups_outlined,
      PhotoType.document => Icons.description_outlined,
      PhotoType.other => Icons.image_outlined,
    };
  }
}

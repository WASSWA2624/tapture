import 'photo_draft.dart';

/// Rotation is metadata only — the original file is never rewritten
/// (FE-SEC-08).
abstract final class PhotoRotate {
  /// Returns [photo] with [degrees] normalised to 0/90/180/270.
  static PhotoDraft apply(PhotoDraft photo, int degrees) {
    final int next = ((photo.rotationDegrees + degrees) % 360 + 360) % 360;
    final int snapped = (next / 90).round() * 90 % 360;
    return photo.copyWith(rotationDegrees: snapped);
  }

  /// Clears rotation metadata back to the original orientation.
  static PhotoDraft revert(PhotoDraft photo) {
    return photo.copyWith(rotationDegrees: 0);
  }
}

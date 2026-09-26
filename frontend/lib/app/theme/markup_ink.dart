import 'dart:ui';

/// Inks for drawing and typing on a photo (FBK0000151, FBK0000152). They are
/// the same in every theme, because they become part of the saved image.
enum MarkupInk {
  /// The default: reads on most photos and marks a fault.
  red(Color(0xFFE53935)),

  /// Reads on dark photos.
  yellow(Color(0xFFFDD835)),

  /// Reads on dark photos and on a dark backing.
  white(Color(0xFFFFFFFF)),

  /// Reads on light photos.
  black(Color(0xFF000000)),

  /// A second colour for a second kind of mark.
  blue(Color(0xFF1E88E5)),

  /// A mark that says a part is fine.
  green(Color(0xFF43A047));

  const MarkupInk(this.color);

  /// The ink as drawn on screen and written into the photo.
  final Color color;
}

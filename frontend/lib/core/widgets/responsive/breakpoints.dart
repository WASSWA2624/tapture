import 'package:flutter/widgets.dart';

/// The type this file is named for (FE-STR-06). The contract name is
/// [SizeClass].
typedef Breakpoints = SizeClass;

/// Window width buckets. These three numbers exist only here (FE-RESP-01).
enum SizeClass {
  /// Narrower than 600 dp (phones in portrait).
  compact,

  /// 600 dp inclusive through 1023 dp.
  medium,

  /// 1024 dp and above (tablets and desktops).
  expanded;

  /// Resolves [width] onto a size class.
  static SizeClass fromWidth(double width) {
    if (width < _compactMax) {
      return SizeClass.compact;
    }
    if (width < _expandedMin) {
      return SizeClass.medium;
    }
    return SizeClass.expanded;
  }
}

/// Compact ends just below this width, in logical pixels.
const double _compactMax = 600;

/// Expanded begins at this width, in logical pixels.
const double _expandedMin = 1024;

/// Size class and per-class values from the window, never from a raw width
/// (FE-RESP-02).
extension SizeClassX on BuildContext {
  /// The size class of the current window.
  SizeClass get sizeClass => SizeClass.fromWidth(MediaQuery.sizeOf(this).width);

  /// Picks the value for the current class, falling back to the next smaller
  /// one when a larger class is omitted.
  T responsive<T>({required T compact, T? medium, T? expanded}) {
    return switch (sizeClass) {
      SizeClass.compact => compact,
      SizeClass.medium => medium ?? compact,
      SizeClass.expanded => expanded ?? medium ?? compact,
    };
  }
}

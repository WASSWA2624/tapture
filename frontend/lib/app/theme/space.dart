part of 'dimensions.dart';

/// Four-point spacing scale from 2 to 48, identical in every mode
/// (FE-THEME-03).
abstract final class Space {
  /// Half-step; hairline gaps and outline-adjacent padding.
  static const double x0 = 2;

  /// 4.
  static const double x1 = 4;

  /// 8.
  static const double x2 = 8;

  /// 12.
  static const double x3 = 12;

  /// 16.
  static const double x4 = 16;

  /// 20.
  static const double x5 = 20;

  /// 24.
  static const double x6 = 24;

  /// 28.
  static const double x7 = 28;

  /// 32.
  static const double x8 = 32;

  /// 36.
  static const double x9 = 36;

  /// 40.
  static const double x10 = 40;

  /// 44.
  static const double x11 = 44;

  /// 48; matches [Sizes.minTapTarget].
  static const double x12 = 48;
}

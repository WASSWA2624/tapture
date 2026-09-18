import 'dart:ui' show Display;

import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// The window and display as they are right now, for diagnostics such as a
/// feedback entry. Measured here so no feature measures the screen
/// (FE-RESP-02).
@immutable
final class ViewportMetrics {
  /// Creates metrics. Sizes are logical pixels.
  const ViewportMetrics({
    required this.viewport,
    required this.devicePixelRatio,
    required this.display,
    required this.orientation,
    required this.sizeClass,
    required this.textScale,
  });

  /// The window's logical size.
  final Size viewport;

  /// Physical pixels per logical pixel.
  final double devicePixelRatio;

  /// The whole display's logical size.
  final Size display;

  /// Portrait or landscape.
  final Orientation orientation;

  /// The window's size class.
  final SizeClass sizeClass;

  /// How much the operator has scaled body text; 1 is the default.
  final double textScale;
}

/// Reads [ViewportMetrics] from the nearest view.
extension ViewportMetricsX on BuildContext {
  /// The metrics of the window this context is drawn in.
  ViewportMetrics get viewportMetrics {
    final Size viewport = MediaQuery.sizeOf(this);
    final Display display = View.of(this).display;
    final double ratio = display.devicePixelRatio <= 0
        ? 1
        : display.devicePixelRatio;
    return ViewportMetrics(
      viewport: viewport,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(this),
      display: display.size / ratio,
      orientation: MediaQuery.orientationOf(this),
      sizeClass: SizeClass.fromWidth(viewport.width),
      textScale: MediaQuery.textScalerOf(this).scale(1),
    );
  }
}

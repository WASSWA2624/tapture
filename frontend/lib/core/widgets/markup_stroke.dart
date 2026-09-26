import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/core/constants/app_constants.dart';

/// One freehand stroke on a photo, kept with the ink and size it was
/// started in (FBK0000151).
@immutable
final class MarkupStroke {
  /// Creates a stroke.
  const MarkupStroke({
    required this.points,
    required this.ink,
    required this.size,
  });

  /// Points as fractions of the photo as shown, after its rotation.
  final List<Offset> points;

  /// The ink the stroke was drawn in.
  final MarkupInk ink;

  /// Size index into [AppConstants.markup] stroke fractions.
  final int size;

  /// The stroke width as a fraction of the photo's short edge.
  double get widthFraction {
    final List<double> steps = AppConstants.markup.strokeFractions;
    return steps[size.clamp(0, steps.length - 1)];
  }

  /// This stroke with [point] added at the end.
  MarkupStroke adding(Offset point) {
    return MarkupStroke(
      points: <Offset>[...points, point],
      ink: ink,
      size: size,
    );
  }
}

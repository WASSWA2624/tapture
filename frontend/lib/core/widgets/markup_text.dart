import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/core/constants/app_constants.dart';

/// A block of text typed onto a photo: its lines, ink, size and where its
/// centre sits (FBK0000152).
@immutable
final class MarkupText {
  /// Creates a text block, centred low on the photo by default.
  const MarkupText({
    required this.text,
    required this.ink,
    required this.size,
    this.centre = const Offset(0.5, 0.8),
    this.backing = true,
  });

  /// The words, with a line break between lines.
  final String text;

  /// The ink the words are drawn in.
  final MarkupInk ink;

  /// Size index into [AppConstants.markup] text fractions.
  final int size;

  /// The block's centre as fractions of the photo as shown, after its
  /// rotation.
  final Offset centre;

  /// Whether a dark backing sits behind the words.
  final bool backing;

  /// One line's height as a fraction of the photo's height.
  double get lineFraction {
    final List<double> steps = AppConstants.markup.textFractions;
    return steps[size.clamp(0, steps.length - 1)];
  }

  /// This block with the given parts replaced.
  MarkupText copyWith({
    String? text,
    MarkupInk? ink,
    int? size,
    Offset? centre,
    bool? backing,
  }) {
    return MarkupText(
      text: text ?? this.text,
      ink: ink ?? this.ink,
      size: size ?? this.size,
      centre: centre ?? this.centre,
      backing: backing ?? this.backing,
    );
  }
}

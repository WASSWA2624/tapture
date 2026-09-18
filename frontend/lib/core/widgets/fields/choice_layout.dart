import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';

/// The tightest radio or checkbox: its mark in a 24dp box. The row it sits
/// in still keeps the 48dp target (FE-A11Y-01).
const VisualDensity compactChoiceDensity = VisualDensity(
  horizontal: VisualDensity.minimumDensity,
  vertical: VisualDensity.minimumDensity,
);

/// Gap between side-by-side options.
const double choiceGap = Space.x1;

/// Width around a compact option's label: the 24dp box, the gap to the
/// label and the space before the next option.
const double _chrome = Sizes.minTapTarget / 2 + Space.x1 + Space.x2;

/// The width of one even column for side-by-side options labelled
/// [labels], or null when they all fit on one line at their own width.
///
/// Options that do not fit fall into balanced columns, so four become two
/// rows of two rather than three and a straggler. Labels are measured in
/// the style they are drawn in, family included.
double? evenChoiceWidth(
  BuildContext context,
  List<String> labels,
  double maxWidth,
) {
  if (!maxWidth.isFinite || labels.isEmpty) {
    return null;
  }
  final TextStyle style = DefaultTextStyle.of(
    context,
  ).style.merge(AppText.label);
  final TextPainter painter = TextPainter(
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  );
  double total = choiceGap * (labels.length - 1);
  double widest = 0;
  for (final String label in labels) {
    painter
      ..text = TextSpan(text: label, style: style)
      ..layout();
    final double width = _chrome + painter.width.ceilToDouble();
    total += width;
    if (width > widest) {
      widest = width;
    }
  }
  painter.dispose();
  if (total <= maxWidth) {
    return null;
  }
  final int fit = ((maxWidth + choiceGap) / (widest + choiceGap)).floor().clamp(
    1,
    labels.length,
  );
  final int rows = (labels.length / fit).ceil();
  final int columns = (labels.length / rows).ceil();
  // Floored so rounding can never push the last column onto a new line.
  return ((maxWidth - choiceGap * (columns - 1)) / columns).floorToDouble();
}

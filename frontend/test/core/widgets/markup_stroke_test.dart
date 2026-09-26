import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/widgets/markup_stroke.dart';

void main() {
  test('a stroke keeps its ink and size as points are added', () {
    const MarkupStroke start = MarkupStroke(
      points: <Offset>[Offset(0.1, 0.2)],
      ink: MarkupInk.yellow,
      size: 2,
    );
    final MarkupStroke longer = start
        .adding(const Offset(0.3, 0.4))
        .adding(const Offset(0.5, 0.6));

    expect(start.points, hasLength(1));
    expect(longer.points, const <Offset>[
      Offset(0.1, 0.2),
      Offset(0.3, 0.4),
      Offset(0.5, 0.6),
    ]);
    expect(longer.ink, MarkupInk.yellow);
    expect(longer.size, 2);
  });

  test('the width comes from the size, and an unknown size is clamped', () {
    for (int size = 0; size < 3; size++) {
      expect(
        MarkupStroke(
          points: const <Offset>[],
          ink: MarkupInk.red,
          size: size,
        ).widthFraction,
        AppConstants.markup.strokeFractions[size],
      );
    }
    expect(
      const MarkupStroke(
        points: <Offset>[],
        ink: MarkupInk.red,
        size: 9,
      ).widthFraction,
      AppConstants.markup.strokeFractions.last,
    );
    expect(
      const MarkupStroke(
        points: <Offset>[],
        ink: MarkupInk.red,
        size: -1,
      ).widthFraction,
      AppConstants.markup.strokeFractions.first,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/widgets/markup_text.dart';

void main() {
  test('a new block sits low and centred, over a backing', () {
    const MarkupText text = MarkupText(
      text: 'Ward 2',
      ink: MarkupInk.white,
      size: 1,
    );
    expect(text.centre, const Offset(0.5, 0.8));
    expect(text.backing, isTrue);
    expect(text.lineFraction, AppConstants.markup.textFractions[1]);
  });

  test('copyWith replaces only what it is given', () {
    const MarkupText text = MarkupText(
      text: 'Ward 2',
      ink: MarkupInk.white,
      size: 1,
    );
    final MarkupText moved = text.copyWith(
      centre: const Offset(0.2, 0.3),
      backing: false,
      size: 2,
    );
    expect(moved.text, 'Ward 2');
    expect(moved.ink, MarkupInk.white);
    expect(moved.size, 2);
    expect(moved.centre, const Offset(0.2, 0.3));
    expect(moved.backing, isFalse);
    expect(moved.lineFraction, AppConstants.markup.textFractions[2]);
  });

  test('an unknown size is clamped to the nearest step', () {
    expect(
      const MarkupText(text: 'a', ink: MarkupInk.red, size: 7).lineFraction,
      AppConstants.markup.textFractions.last,
    );
    expect(
      const MarkupText(text: 'a', ink: MarkupInk.red, size: -2).lineFraction,
      AppConstants.markup.textFractions.first,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/color_swatches.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/surface_levels.dart';
import 'package:tapture/app/theme/type_ramp.dart';

import '../../support/a11y_matchers.dart';
import 'token_harness.dart';

void main() {
  group('swatches', () {
    for (final AppColors colors in tokenModes) {
      final String mode = tokenModeName(colors);
      testWidgets('gallery in $mode', (WidgetTester tester) async {
        await pumpTokenTree(
          tester,
          colors: colors,
          child: const ColorSwatches(),
        );
        await tester.pump();
        await expectLater(
          find.byType(ColorSwatches),
          matchesGoldenFile('goldens/color_swatches_$mode.png'),
        );
        await expectNoA11yIssues(tester);
      });
    }
  });

  group('type ramp', () {
    for (final AppColors colors in tokenModes) {
      final String mode = tokenModeName(colors);
      testWidgets('gallery in $mode at default scale', (
        WidgetTester tester,
      ) async {
        await pumpTokenTree(
          tester,
          colors: colors,
          size: const Size(400, 1200),
          child: const TypeRamp(),
        );
        await tester.pump();
        await expectLater(
          find.byType(TypeRamp),
          matchesGoldenFile('goldens/type_ramp_$mode.png'),
        );
        await expectNoA11yIssues(tester);
      });
    }

    testWidgets('gallery at 200 percent text scale', (
      WidgetTester tester,
    ) async {
      await pumpTokenTree(
        tester,
        colors: AppColors.light,
        textScale: 2,
        size: const Size(400, 2200),
        child: const TypeRamp(),
      );
      await tester.pump();
      await expectLater(
        find.byType(TypeRamp),
        matchesGoldenFile('goldens/type_ramp_text_scale_200.png'),
      );
    });
  });

  group('surface levels', () {
    for (final AppColors colors in tokenModes) {
      final String mode = tokenModeName(colors);
      testWidgets('gallery in $mode', (WidgetTester tester) async {
        await pumpTokenTree(
          tester,
          colors: colors,
          child: const SurfaceLevels(),
        );
        await tester.pump();
        await expectLater(
          find.byType(SurfaceLevels),
          matchesGoldenFile('goldens/surface_levels_$mode.png'),
        );
        await expectNoA11yIssues(tester);
      });
    }
  });
}

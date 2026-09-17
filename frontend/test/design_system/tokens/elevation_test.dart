import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/elevation.dart';

import 'token_harness.dart';

void main() {
  testWidgets(
    'elevation levels exist in light, dark and outdoor with no shadow',
    (WidgetTester tester) async {
      final Map<String, Set<int>> levels = <String, Set<int>>{};
      final Map<String, Set<double>> radii = <String, Set<double>>{};

      for (final AppColors colors in tokenModes) {
        late List<BoxDecoration> decorations;
        await pumpTokenTree(
          tester,
          colors: colors,
          child: Builder(
            builder: (BuildContext context) {
              decorations = <BoxDecoration>[
                for (int level = 0; level <= 3; level++)
                  Elevation.surface(context, level: level),
              ];
              return const SizedBox.shrink();
            },
          ),
        );
        final String mode = tokenModeName(colors);
        levels[mode] = <int>{0, 1, 2, 3};
        radii[mode] = <double>{
          for (final BoxDecoration decoration in decorations)
            (decoration.borderRadius! as BorderRadius).topLeft.x,
        };
        for (final BoxDecoration decoration in decorations) {
          expect(decoration.boxShadow, anyOf(isNull, isEmpty));
          expect(decoration.color, isNotNull);
          expect(decoration.border, isNotNull);
          expect(
            (decoration.borderRadius! as BorderRadius).topLeft.x,
            Radii.md,
          );
        }
      }

      expect(levels['light'], levels['dark']);
      expect(levels['light'], levels['outdoor']);
      expect(radii['light'], radii['dark']);
      expect(radii['light'], radii['outdoor']);
    },
  );

  testWidgets('outdoor thickens outlines without changing radius', (
    WidgetTester tester,
  ) async {
    late BoxDecoration light;
    late BoxDecoration outdoor;
    await pumpTokenTree(
      tester,
      colors: AppColors.light,
      child: Builder(
        builder: (BuildContext context) {
          light = Elevation.surface(context, level: 1);
          return const SizedBox.shrink();
        },
      ),
    );
    await pumpTokenTree(
      tester,
      colors: AppColors.outdoor,
      child: Builder(
        builder: (BuildContext context) {
          outdoor = Elevation.surface(context, level: 1);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(light.borderRadius, outdoor.borderRadius);
    expect(_borderWidth(outdoor), greaterThan(_borderWidth(light)));
  });
}

double _borderWidth(BoxDecoration decoration) {
  final BoxBorder? border = decoration.border;
  if (border is Border) {
    return border.top.width;
  }
  return 0;
}

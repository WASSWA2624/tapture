import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';

import '../../support/a11y_matchers.dart';

void main() {
  group('responsive pair', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      for (final ({String name, double width}) size in _sizes) {
        testWidgets('${size.name} in ${mode.name}', (
          WidgetTester tester,
        ) async {
          await _pumpGallery(tester, mode.theme, width: size.width);
          await tester.pump();
          await expectLater(
            find.byKey(_surface),
            matchesGoldenFile(
              'goldens/responsive_pair_${size.name}_${mode.name}.png',
            ),
          );
          await expectNoA11yIssues(tester);
        });
      }
    }

    for (final ({String name, double width}) size in _sizes) {
      testWidgets('${size.name} stays whole at 200 percent text', (
        WidgetTester tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _pumpGallery(
          tester,
          buildTheme(brightness: Brightness.light),
          width: size.width,
        );
        expect(tester.takeException(), isNull);
        await expectNoA11yIssues(tester);
      });
    }
  });
}

const ValueKey<String> _surface = ValueKey<String>('pair-surface');

List<({String name, ThemeData theme})> get _modes {
  return <({String name, ThemeData theme})>[
    (name: 'light', theme: buildTheme(brightness: Brightness.light)),
    (name: 'dark', theme: buildTheme(brightness: Brightness.dark)),
    (name: 'outdoor', theme: buildOutdoorTheme(Brightness.light)),
  ];
}

const List<({String name, double width})> _sizes =
    <({String name, double width})>[
      (name: 'compact', width: 400),
      (name: 'medium', width: 800),
      (name: 'expanded', width: 1200),
    ];

Future<void> _pumpGallery(
  WidgetTester tester,
  ThemeData theme, {
  required double width,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 600);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final AppColors colors = theme.extension<AppColors>()!;
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      theme: theme,
      home: Scaffold(
        backgroundColor: colors.background,
        body: SingleChildScrollView(
          child: Padding(
            key: _surface,
            padding: const EdgeInsets.all(Space.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Two selects, even shares.
                ResponsivePair(
                  start: AppChoiceField<String>(
                    label: Copy.captureProjectLabel,
                    options: const <Choice<String>>[
                      Choice<String>('a', 'Alpha'),
                    ],
                    value: 'a',
                    alwaysSheet: true,
                    onChanged: (_) {},
                  ),
                  end: AppChoiceField<String>(
                    label: Copy.capturePickTemplate,
                    options: const <Choice<String>>[
                      Choice<String>('b', 'Bravo'),
                    ],
                    value: 'b',
                    alwaysSheet: true,
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(height: Space.x6),
                // Two saves, the primary twice the secondary.
                ResponsivePair(
                  endFlex: 2,
                  start: AppButton(
                    label: Copy.captureSaveRaw,
                    variant: AppButtonVariant.secondary,
                    expand: true,
                    onPressed: () {},
                  ),
                  end: AppPrimaryAction(
                    label: Copy.captureSaveAndAnalyse,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

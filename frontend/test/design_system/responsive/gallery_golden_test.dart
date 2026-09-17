import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/widgets/responsive/content_constraint.dart';

import '../../support/a11y_matchers.dart';

void main() {
  group('content constraint', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(ContentConstraint),
          matchesGoldenFile('goldens/content_constraint_${mode.name}.png'),
        );
        await expectNoA11yIssues(tester);
      });
    }
  });
}

List<({String name, ThemeData theme})> get _modes {
  return <({String name, ThemeData theme})>[
    (name: 'light', theme: buildTheme(brightness: Brightness.light)),
    (name: 'dark', theme: buildTheme(brightness: Brightness.dark)),
    (name: 'outdoor', theme: buildOutdoorTheme(Brightness.light)),
  ];
}

Future<void> _pumpGallery(WidgetTester tester, ThemeData theme) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 800);
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
        body: ContentConstraint(
          child: ColoredBox(
            color: colors.surface,
            child: Padding(
              padding: const EdgeInsets.all(Space.x4),
              child: Text(
                'Readable column',
                style: AppText.body.copyWith(color: colors.onSurface),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

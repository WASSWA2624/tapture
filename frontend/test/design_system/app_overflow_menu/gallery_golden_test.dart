import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';

void main() {
  group('app overflow menu', () {
    for (final ({String name, ThemeData theme}) mode in _modes) {
      testWidgets('gallery in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile('goldens/app_overflow_menu_${mode.name}.png'),
        );
      });

      testWidgets('both variants in ${mode.name}', (WidgetTester tester) async {
        await _pumpGallery(tester, mode.theme, states: true);
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile(
            'goldens/app_overflow_menu_variants_${mode.name}.png',
          ),
        );
      });

      testWidgets('both variants at 200 percent in ${mode.name}', (
        WidgetTester tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _pumpGallery(
          tester,
          mode.theme,
          states: true,
          surface: const Size(400, 640),
        );
        await tester.pump();
        await expectLater(
          find.byType(AppPage),
          matchesGoldenFile(
            'goldens/app_overflow_menu_variants_text2_${mode.name}.png',
          ),
        );
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

Future<void> _pumpGallery(
  WidgetTester tester,
  ThemeData theme, {
  bool states = false,
  Size surface = const Size(400, 240),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = surface;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      theme: theme,
      home: AppPage(
        title: 'Overflow',
        body: states ? _states(theme) : _outlinedOnly(),
      ),
    ),
  );
}

Widget _outlinedOnly() {
  return const Wrap(
    spacing: Space.x2,
    runSpacing: Space.x2,
    children: <Widget>[
      AppOverflowMenu(
        key: ValueKey<String>('app-overflow'),
        items: <AppOverflowAction>[
          AppOverflowAction(
            icon: Icons.save_outlined,
            label: Copy.save,
            onTap: _ignorePress,
          ),
        ],
      ),
    ],
  );
}

Widget _states(ThemeData theme) {
  const List<AppOverflowAction> items = <AppOverflowAction>[
    AppOverflowAction(
      icon: Icons.save_outlined,
      label: Copy.save,
      onTap: _ignorePress,
    ),
  ];
  final Color fill =
      theme.extension<AppColors>()?.surfaceVariant ??
      AppColors.light.surfaceVariant;
  Widget filled(Widget child) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: child,
    );
  }

  return Wrap(
    spacing: Space.x2,
    runSpacing: Space.x2,
    children: <Widget>[
      const AppOverflowMenu(items: items),
      filled(const AppOverflowMenu(items: items)),
      filled(const AppOverflowMenu(items: items)),
      filled(const AppOverflowMenu(items: items)),
      const AppOverflowMenu(items: <AppOverflowAction>[]),
      const AppOverflowMenu(outlined: false, items: items),
      filled(const AppOverflowMenu(outlined: false, items: items)),
      filled(const AppOverflowMenu(outlined: false, items: items)),
      filled(const AppOverflowMenu(outlined: false, items: items)),
      const AppOverflowMenu(outlined: false, items: <AppOverflowAction>[]),
    ],
  );
}

void _ignorePress() {}

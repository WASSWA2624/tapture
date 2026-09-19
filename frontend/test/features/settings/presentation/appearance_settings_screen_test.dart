import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/files/files.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/features/settings/presentation/appearance_settings_screen.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets(
    'four options; System is selected; Dark persists across a restart',
    (WidgetTester tester) async {
      final Map<String, String> backing = <String, String>{};
      await _pump(tester, backing);
      expect(find.text(Copy.themeModeSystem), findsOneWidget);
      expect(find.text(Copy.themeModeLight), findsOneWidget);
      expect(find.text(Copy.themeModeDark), findsOneWidget);
      expect(find.text(Copy.themeModeOutdoor), findsOneWidget);
      expect(
        tester
            .widget<RadioGroup<AppThemeMode>>(
              find.byType(RadioGroup<AppThemeMode>),
            )
            .groupValue,
        AppThemeMode.system,
      );
      expect(
        find.byType(AppRadioGroup<AppThemeMode>),
        hasSemanticLabel(Copy.settingsAppearanceTitle),
      );
      expect(find.byType(AppRadioGroup<AppThemeMode>), meetsTapTarget());

      await tester.tap(find.text(Copy.themeModeDark));
      await tester.pumpAndSettle();
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(AppearanceSettingsScreen)),
      );
      expect(container.read(themeModeProvider), AppThemeMode.dark);
      expect(
        backing[AppConstants.preferences.themeMode],
        AppThemeMode.dark.name,
      );

      final ProviderContainer restarted = ProviderContainer(
        overrides: <Override>[
          themeModeProvider.overrideWith(
            () => ThemeModeController.withStore(TextStore.memory(backing)),
          ),
        ],
      );
      addTearDown(restarted.dispose);
      expect(restarted.read(themeModeProvider), AppThemeMode.dark);
    },
  );

  for (final ({Size size, String name}) viewport in _viewports) {
    for (final double scale in <double>[1, 2]) {
      testWidgets(
        'does not overflow at ${viewport.name} and ${scale * 100} percent text',
        (WidgetTester tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = viewport.size;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          if (scale != 1) {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
          }
          await _pump(tester, <String, String>{});
          expect(tester.takeException(), isNull);
          expect(find.byType(AppearanceSettingsScreen), findsOneWidget);
        },
      );
    }
  }
}

const List<({Size size, String name})> _viewports =
    <({Size size, String name})>[
      (size: Size(360, 800), name: '360 portrait'),
      (size: Size(800, 360), name: '360 landscape'),
      (size: Size(700, 800), name: '700 portrait'),
      (size: Size(800, 700), name: '700 landscape'),
      (size: Size(1280, 800), name: '1280 portrait'),
      (size: Size(800, 1280), name: '1280 landscape'),
    ];

Future<void> _pump(WidgetTester tester, Map<String, String> backing) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        themeModeProvider.overrideWith(
          () => ThemeModeController.withStore(TextStore.memory(backing)),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const AppearanceSettingsScreen(),
      ),
    ),
  );
}

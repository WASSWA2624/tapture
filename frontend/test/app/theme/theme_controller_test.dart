import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/files/files.dart';

void main() {
  test('AppThemeMode round-trips through the fake store', () async {
    final Map<String, String> backing = <String, String>{};
    final ProviderContainer first = _container(backing);
    addTearDown(first.dispose);

    expect(first.read(themeModeProvider), AppThemeMode.system);
    await first.read(themeModeProvider.notifier).setMode(AppThemeMode.outdoor);
    expect(
      backing[AppConstants.preferences.themeMode],
      AppThemeMode.outdoor.name,
    );

    final ProviderContainer restarted = _container(backing);
    addTearDown(restarted.dispose);
    expect(restarted.read(themeModeProvider), AppThemeMode.outdoor);
  });

  test('an unknown stored name falls back to system', () {
    final ProviderContainer container = _container(<String, String>{
      AppConstants.preferences.themeMode: 'not-a-mode',
    });
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), AppThemeMode.system);
  });

  testWidgets('the restored mode is on the first frame', (
    WidgetTester tester,
  ) async {
    final Map<String, String> backing = <String, String>{
      AppConstants.preferences.themeMode: AppThemeMode.dark.name,
    };
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(
            () => ThemeModeController.withStore(TextStore.memory(backing)),
          ),
          networkOnlineOverride(),
        ],
        child: const TaptureApp(),
      ),
    );

    final MaterialApp material = tester.widget(find.byType(MaterialApp));
    expect(material.themeMode, ThemeMode.dark);
    expect(
      identical(material.darkTheme!.extension<AppColors>(), AppColors.dark),
      isTrue,
    );
  });
}

ProviderContainer _container(Map<String, String> backing) {
  return ProviderContainer(
    overrides: [
      themeModeProvider.overrideWith(
        () => ThemeModeController.withStore(TextStore.memory(backing)),
      ),
    ],
  );
}

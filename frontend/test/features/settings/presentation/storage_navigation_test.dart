import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/locale_controller.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/files/files.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/presentation/settings_screen.dart';
import 'package:tapture/features/settings/presentation/storage_settings_screen.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/screen_matrix.dart';

void main() {
  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    for (final Locale locale in <Locale>[
      const Locale('en'),
      const Locale('en', 'XA'),
    ]) {
      testWidgets(
        'Storage keeps recovery without Check files in ${locale.toLanguageTag()} ${cell.description}',
        (WidgetTester tester) async {
          final GoRouter router = await _pump(tester, cell, locale);
          router.go(AppRoutes.more);
          await tester.pumpAndSettle();
          final LocalizedCopy settingsCopy = Copy.of(
            tester.element(find.byType(SettingsScreen)),
          );
          final Finder storage = find.widgetWithText(
            AppListTile,
            settingsCopy.settingsStorageTitle,
          );
          await tester.ensureVisible(storage);
          await tester.tap(storage);
          await tester.pumpAndSettle();
          expect(router.state.uri.path, AppRoutes.settingsStorage);
          expect(find.byType(StorageSettingsScreen), findsOneWidget);
          final LocalizedCopy copy = Copy.of(
            tester.element(find.byType(StorageSettingsScreen)),
          );
          expect(find.text(copy.storageCheckTitle), findsNothing);
          expect(
            find.byKey(const ValueKey<String>('storage-check-files')),
            findsNothing,
          );
          final Finder recycle = find.byKey(
            const ValueKey<String>('storage-recycle-bin'),
          );
          await tester.ensureVisible(recycle);
          expect(recycle.hitTestable(), findsOneWidget);
          expect(find.text(copy.settingsRetentionHeader), findsOneWidget);
          router.go(AppRoutes.settingsStorageCheck);
          await tester.pumpAndSettle();
          expect(router.state.uri.path, AppRoutes.settingsStorage);
          expect(find.byType(StorageSettingsScreen), findsOneWidget);
          expect(find.text(copy.storageCheckTitle), findsNothing);
          expect(tester.takeException(), isNull);
        },
        variant: kIsWeb
            ? TargetPlatformVariant.only(defaultTargetPlatform)
            : TargetPlatformVariant.all(),
      );
    }
  }
}

Future<GoRouter> _pump(
  WidgetTester tester,
  ScreenMatrix cell,
  Locale locale,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = cell.size;
  tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  final AppThemeMode mode = cell.outdoor
      ? AppThemeMode.outdoor
      : cell.brightness == Brightness.dark
      ? AppThemeMode.dark
      : AppThemeMode.light;
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectSettingsStoreProvider.overrideWithValue(SettingsStore.fake()),
        themeModeProvider.overrideWith(
          () => ThemeModeController.withStore(TextStore.memory()),
        ),
        storageSettingsOverride(cacheBytes: 0),
      ],
      child: const TaptureApp(receiveIncomingBundles: false),
    ),
  );
  final ProviderContainer container = ProviderScope.containerOf(
    tester.element(find.byType(TaptureApp)),
  );
  container.read(appLocaleProvider.notifier).select(locale);
  await container.read(themeModeProvider.notifier).setMode(mode);
  await tester.pumpAndSettle();
  return container.read(routerProvider);
}

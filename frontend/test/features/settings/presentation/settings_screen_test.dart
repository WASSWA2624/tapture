import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart' show TaptureApp;
import 'package:tapture/app/router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/files/files.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/settings/presentation/appearance_settings_screen.dart';
import 'package:tapture/features/settings/presentation/settings_screen.dart';
import 'package:tapture/features/settings/presentation/storage_settings_screen.dart';

import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';

void main() {
  testWidgets('the actual Settings Storage tile opens the production route', (
    WidgetTester tester,
  ) async {
    _compact(tester);
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: <Override>[
          storageSettingsOverride(cacheBytes: 0),
          themeModeProvider.overrideWith(
            () => ThemeModeController.withStore(TextStore.memory()),
          ),
        ],
        child: const TaptureApp(receiveIncomingBundles: false),
      ),
    );
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(TaptureApp)),
    );
    final GoRouter router = container.read(routerProvider);
    router.go(AppRoutes.more);
    await tester.pumpAndSettle();
    final Finder storage = find.widgetWithText(
      AppListTile,
      Copy.settingsStorageTitle,
    );
    await tester.ensureVisible(storage);
    await tester.tap(storage);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.settingsStorage);
    expect(find.byType(StorageSettingsScreen), findsOneWidget);
    expect(find.text(Copy.storageCheckTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });

  setUpAll(ScreenFonts.load);
  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'Settings removes global shortcuts across ${cell.description}',
      (WidgetTester tester) async {
        await _pump(tester, cell: cell);
        await tester.pumpAndSettle();
        expect(find.text(Copy.navQueue), findsNothing);
        expect(find.text(Copy.navTranscripts), findsNothing);
        expect(find.text(Copy.backendSettingsTitle), findsNothing);
        expect(find.text(Copy.relayTitle), findsNothing);
        expect(
          find.widgetWithText(AppListTile, Copy.settingsAiTitle),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.widgetWithText(AppListTile, Copy.settingsAboutTitle),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.all(),
    );
  }

  for (final (String, Brightness, bool) mode in <(String, Brightness, bool)>[
    ('light', Brightness.light, false),
    ('dark', Brightness.dark, false),
    ('outdoor', Brightness.light, true),
  ]) {
    for (final double scale in <double>[1, 2]) {
      testWidgets('Settings index golden ${mode.$1} text$scale', (
        WidgetTester tester,
      ) async {
        await _pump(
          tester,
          cell: ScreenMatrix(const Size(393, 852), scale, mode.$2, mode.$3),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/settings_index_text${scale.toInt()}_${mode.$1}.png',
          ),
        );
      });
    }
  }

  testWidgets(
    'Settings keeps the same destinations in pseudo-locale at text 2',
    (WidgetTester tester) async {
      await _pump(
        tester,
        locale: const Locale('en', 'XA'),
        cell: const ScreenMatrix(Size(393, 320), 2, Brightness.light, false),
      );
      await tester.pumpAndSettle();
      final LocalizedCopy copy = Copy.of(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(find.text(copy.backendSettingsTitle), findsNothing);
      expect(find.text(copy.relayTitle), findsNothing);
      await tester.ensureVisible(
        find.widgetWithText(AppListTile, copy.settingsAboutTitle),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the root lists every section in order in four groups', (
    WidgetTester tester,
  ) async {
    _compact(tester);
    await _pump(tester);
    await tester.pumpAndSettle();

    final List<String> titles = <String>[
      Copy.operatorProfileTitle,
      Copy.settingsCaptureTitle,
      Copy.settingsAiTitle,
      Copy.settingsLanguageTitle,
      Copy.settingsAppearanceTitle,
      Copy.settingsStorageTitle,
      Copy.settingsFilesTitle,
      Copy.appLockTitle,
      Copy.privacyScreenTitle,
      Copy.settingsAboutTitle,
    ];
    expect(find.byType(AppListTile), findsNWidgets(titles.length));
    double previous = double.negativeInfinity;
    for (final String title in titles) {
      final Finder row = find.widgetWithText(AppListTile, title);
      expect(row, findsOneWidget, reason: title);
      final double top = tester.getTopLeft(row).dy;
      expect(top, greaterThan(previous), reason: title);
      previous = top;
    }

    // Templates lives in compact More; queue and transcripts stay project actions.
    expect(find.text(Copy.navTemplates), findsNothing);
    expect(find.text(Copy.navQueue), findsNothing);
    expect(find.text(Copy.navTranscripts), findsNothing);
    expect(find.text(Copy.backendSettingsTitle), findsNothing);
    expect(find.text(Copy.relayTitle), findsNothing);

    expect(find.text(Copy.settingsGroupProfileCapture), findsOneWidget);
    expect(find.text(Copy.settingsGroupIntelligenceAppearance), findsOneWidget);
    expect(find.text(Copy.settingsGroupStorageSecurity), findsOneWidget);
    expect(find.text(Copy.settingsGroupAbout), findsWidgets);
  });

  testWidgets('from medium width the root lists the More menu first', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text(Copy.navMoreMenu), findsOneWidget);
    expect(find.text(Copy.navQueue), findsNothing);
    expect(find.text(Copy.navTranscripts), findsNothing);
    expect(find.text(Copy.backendSettingsTitle), findsNothing);
    expect(find.text(Copy.relayTitle), findsNothing);
    for (final String title in <String>[
      Copy.navTemplates,
      Copy.recycleBinTitle,
    ]) {
      expect(find.widgetWithText(AppListTile, title), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(title)).dy,
        lessThan(tester.getTopLeft(find.text(Copy.operatorProfileTitle)).dy),
      );
    }
  });

  testWidgets('the More rows open Templates and Recycle bin', (
    WidgetTester tester,
  ) async {
    for (final String path in <String>[
      AppRoutes.templates,
      AppRoutes.recycleBin,
    ]) {
      final GoRouter router = _router(<String>[path]);
      addTearDown(router.dispose);
      await _pumpRouter(tester, router);

      await tester.tap(find.byKey(ValueKey<String>('settings-more-$path')));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, path);
      expect(find.text('page $path'), findsOneWidget);
    }
  });

  testWidgets('Language and Files open their own screens', (
    WidgetTester tester,
  ) async {
    _compact(tester);
    for (final ({String title, String path}) row
        in <({String title, String path})>[
          (title: Copy.settingsLanguageTitle, path: AppRoutes.settingsLanguage),
          (title: Copy.settingsFilesTitle, path: AppRoutes.settingsFiles),
        ]) {
      final GoRouter router = _router(<String>[row.path]);
      addTearDown(router.dispose);
      await _pumpRouter(tester, router);

      await tester.ensureVisible(find.text(row.title));
      await tester.tap(find.text(row.title));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, row.path);
      expect(find.text('page ${row.path}'), findsOneWidget);
    }
  });

  testWidgets('loading renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    final Completer<List<({String title, String subtitle, String? route})>>
    pending =
        Completer<List<({String title, String subtitle, String? route})>>();
    await _pump(tester, load: () => pending.future);
    await tester.pump();

    expect(find.byType(AppSkeleton), findsOneWidget);
    pending.complete(
      const <({String title, String subtitle, String? route})>[],
    );
  });

  testWidgets('an empty list renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      load: () async {
        return const <({String title, String subtitle, String? route})>[];
      },
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.settingsEmptyHeadline), findsOneWidget);
  });

  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      load: () async {
        throw Exception('Settings could not be read.');
      },
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
  });

  testWidgets('Appearance follows Language and opens the screen', (
    WidgetTester tester,
  ) async {
    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.more,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.more,
          builder: (BuildContext _, GoRouterState _) {
            return const SettingsScreen();
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'appearance',
              builder: (BuildContext _, GoRouterState _) {
                return const AppearanceSettingsScreen();
              },
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: <Override>[
          themeModeProvider.overrideWith(
            () => ThemeModeController.withStore(TextStore.memory()),
          ),
        ],
        child: MaterialApp.router(
          theme: buildTheme(brightness: Brightness.light),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text(Copy.settingsLanguageTitle)).dy,
      lessThan(tester.getTopLeft(find.text(Copy.settingsAppearanceTitle)).dy),
    );
    expect(
      tester.getTopLeft(find.text(Copy.settingsAppearanceTitle)).dy,
      lessThan(tester.getTopLeft(find.text(Copy.settingsStorageTitle)).dy),
    );

    await tester.ensureVisible(find.text(Copy.settingsAppearanceTitle));
    await tester.tap(find.text(Copy.settingsAppearanceTitle));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.settingsAppearance);
    expect(find.byType(AppearanceSettingsScreen), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  Future<List<({String title, String subtitle, String? route})>> Function()?
  load,
  ScreenMatrix? cell,
  Locale locale = const Locale('en'),
}) {
  if (cell != null) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = cell.size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  return tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        if (load != null) settingsScreenOverride(load: load),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ScreenFonts.theme(
          buildTheme(
            brightness: cell?.brightness ?? Brightness.light,
            outdoor: cell?.outdoor ?? false,
          ),
        ),
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(cell?.textScale ?? 1)),
          child: child!,
        ),
        home: const SettingsScreen(),
      ),
    ),
  );
}

/// A phone: the More menu carries Templates, Recycle bin and Settings.
void _compact(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 1600);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Settings over stand-in pages at [paths], so a row's tap is observable
/// without the whole route table.
GoRouter _router(List<String> paths) {
  return GoRouter(
    initialLocation: AppRoutes.more,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.more,
        builder: (BuildContext _, GoRouterState _) => const SettingsScreen(),
      ),
      for (final String path in paths)
        GoRoute(
          path: path,
          builder: (BuildContext _, GoRouterState _) => Text('page $path'),
        ),
    ],
  );
}

Future<void> _pumpRouter(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

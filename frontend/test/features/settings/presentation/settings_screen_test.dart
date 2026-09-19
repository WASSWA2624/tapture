import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/files/files.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/settings/presentation/appearance_settings_screen.dart';
import 'package:tapture/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('the root lists every section as one tile', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text(Copy.operatorProfileTitle), findsOneWidget);
    expect(find.text(Copy.navCapture), findsOneWidget);
    expect(find.text(Copy.settingsAiTitle), findsOneWidget);
    expect(find.text(Copy.settingsLanguageTitle), findsOneWidget);
    expect(find.text(Copy.settingsAppearanceTitle), findsOneWidget);
    expect(find.text(Copy.settingsStorageTitle), findsOneWidget);
    expect(find.text(Copy.settingsFilesTitle), findsOneWidget);
    expect(find.text(Copy.settingsSecurityTitle), findsOneWidget);
    expect(find.text(Copy.settingsAboutTitle), findsOneWidget);
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
}) {
  return tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        if (load != null) settingsScreenOverride(load: load),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const SettingsScreen(),
      ),
    ),
  );
}

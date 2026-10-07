import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/files/files.dart';
import 'package:tapture/core/widgets/app_icons.dart';

import '../support/a11y_matchers.dart';

void main() {
  testWidgets('More opens an icon-labelled menu with the minimal radius', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester);
    expect(find.byTooltip(Copy.navMoreMenu), findsOneWidget);
    final Finder more = find.widgetWithText(
      NavigationDestination,
      Copy.navMoreMenu,
    );
    expect(more, meetsTapTarget());
    expect(
      find.descendant(of: more, matching: find.byIcon(AppIcons.moreHorizontal)),
      findsOneWidget,
    );

    await tester.tap(more);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.projects);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    expect(find.byType(PopupMenuItem<int>), findsNWidgets(3));
    expect(_option(AppRoutes.queue), findsNothing);
    expect(_option(RoutePaths.transcripts), findsNothing);
    for (final ({String path, String label, IconData icon}) option
        in _options) {
      final Finder row = _option(option.path);
      expect(row, meetsTapTarget());
      expect(
        find.descendant(of: row, matching: find.text(option.label)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.byIcon(option.icon)),
        findsOneWidget,
      );
    }
    final Material menu = tester.widget<Material>(
      find
          .ancestor(
            of: _option(AppRoutes.templates),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(
      (menu.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(Radii.md),
    );
    expect(tester.takeException(), isNull);
  });

  test('More is the horizontal three dots and the bin has its own icon', () {
    expect(AppIcons.moreHorizontal, Icons.more_horiz);
    // One icon per concept: Restore stays the action's glyph (FE-CONS-08).
    expect(AppIcons.recycleBin, isNot(AppIcons.restore));
  });

  for (final ({String path, String label, IconData icon}) option in _options) {
    testWidgets('${option.label} opens from More and selects its branch', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pump(tester, projectId: 'p1');
      await _openMore(tester);
      await tester.tap(_option(option.path));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, option.path);
      expect(find.byType(PopupMenuItem<int>), findsNothing);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      expect(_container(tester).read(openProjectIdProvider), 'p1');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('outside tap and Back dismiss More and preserve a typed search', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester, projectId: 'p1');
    router.go(AppRoutes.records);
    await tester.pumpAndSettle();
    final Finder search = find.descendant(
      of: find.byKey(const ValueKey<String>('records-search')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(search, 'saved search');

    await _openMore(tester);
    await tester.tapAt(const Offset(10, 100));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<int>), findsNothing);
    expect(router.state.uri.path, AppRoutes.records);
    expect(find.text('saved search'), findsOneWidget);

    await _openMore(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<int>), findsNothing);
    expect(router.state.uri.path, AppRoutes.records);
    expect(find.text('saved search'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(_container(tester).read(openProjectIdProvider), 'p1');
  });

  testWidgets('More fits a small phone with large text in every theme', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final AppThemeMode mode in <AppThemeMode>[
      AppThemeMode.light,
      AppThemeMode.dark,
      AppThemeMode.outdoor,
    ]) {
      await _pump(tester, size: const Size(320, 480), mode: mode);
      await _openMore(tester);
      for (final ({String path, String label, IconData icon}) option
          in _options) {
        final Finder row = _option(option.path);
        expect(row, meetsTapTarget());
        expect(tester.getRect(row).left, greaterThanOrEqualTo(0));
        expect(tester.getRect(row).right, lessThanOrEqualTo(320));
        expect(tester.getRect(row).top, greaterThanOrEqualTo(0));
        expect(tester.getRect(row).bottom, lessThanOrEqualTo(480));
      }
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a More destination survives the change to a desktop rail', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester, projectId: 'p1');
    await _openMore(tester);
    await tester.tap(_option(AppRoutes.templates));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.templates);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      3,
    );
    expect(_container(tester).read(openProjectIdProvider), 'p1');

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text(Copy.navMore),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.more);
    expect(find.byType(PopupMenuItem<int>), findsNothing);
  });

  testWidgets('an open More menu remains usable when the bar becomes a rail', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester, projectId: 'p1');
    await _openMore(tester);
    tester.view.physicalSize = const Size(800, 600);
    await tester.pumpAndSettle();
    await tester.tap(_option(AppRoutes.templates));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.templates);
    expect(find.byType(PopupMenuItem<int>), findsNothing);
    expect(_container(tester).read(openProjectIdProvider), 'p1');
    expect(tester.takeException(), isNull);
  });
}

final List<({String path, String label, IconData icon})> _options =
    <({String path, String label, IconData icon})>[
      (
        path: AppRoutes.templates,
        label: Copy.navTemplates,
        icon: AppIcons.template,
      ),
      (
        path: AppRoutes.recycleBin,
        label: Copy.recycleBinTitle,
        icon: AppIcons.recycleBin,
      ),
      (
        path: AppRoutes.more,
        label: Copy.settingsTitle,
        icon: AppIcons.settings,
      ),
    ];

Finder _option(String path) => find.byKey(ValueKey<String>('nav-more-$path'));

Future<void> _openMore(WidgetTester tester) async {
  await tester.tap(
    find.widgetWithText(NavigationDestination, Copy.navMoreMenu),
  );
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(TaptureApp)));

Future<GoRouter> _pump(
  WidgetTester tester, {
  Size size = const Size(400, 800),
  String? projectId,
  AppThemeMode mode = AppThemeMode.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      retry: (int _, Object _) => null,
      overrides: <Override>[
        networkOnlineOverride(),
        themeModeProvider.overrideWith(
          () => ThemeModeController.withStore(
            TextStore.memory(<String, String>{
              AppConstants.preferences.themeMode: mode.name,
            }),
          ),
        ),
      ],
      child: const TaptureApp(),
    ),
  );
  await tester.pumpAndSettle();
  if (projectId != null) {
    _container(tester).read(openProjectIdProvider.notifier).open(projectId);
    await tester.pumpAndSettle();
  }
  return _container(tester).read(routerProvider);
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/locale_controller.dart';
import 'package:tapture/app/nav_shell.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/shell_destination.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/files/files.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/records/presentation/recycle_bin_screen.dart';
import 'package:tapture/features/records/records.dart'
    show recordRepositoryProvider;
import 'package:tapture/features/settings/presentation/settings_screen.dart';
import 'package:tapture/features/settings/settings.dart';

import '../features/projects/fakes/fake_project_repository.dart';
import '../features/records/fakes/fake_record_repository.dart';
import '../support/a11y_matchers.dart';
import '../support/factories.dart';
import '../support/screen_fonts.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  test(
    'home tabs are Projects, Templates and Settings; the bin stays in Settings',
    () {
      expect(
        navigationDestinations.map((ShellDestination d) => d.path),
        <String>[RoutePaths.projects, RoutePaths.templates, RoutePaths.more],
      );
      expect(shellDestinations, hasLength(2));
      expect(
        navigationDestinations.any(
          (ShellDestination d) => d.path == RoutePaths.recycleBin,
        ),
        isFalse,
      );
    },
  );

  for (final double width in <double>[320, 393, 800, 1200]) {
    for (final double scale in <double>[1, 2]) {
      for (final TextDirection direction in TextDirection.values) {
        testWidgets(
          'home navigation and Settings bin at $width/$scale/$direction',
          (WidgetTester tester) async {
            final _Fixture fixture = await _pump(
              tester,
              width: width,
              scale: scale,
              direction: direction,
            );
            final Finder navigation = find.byKey(
              ValueKey<String>(width < 600 ? 'nav-bar' : 'nav-rail'),
            );
            expect(navigation, findsOneWidget);
            expect(
              find.descendant(
                of: navigation,
                matching: find.text(fixture.copy.recycleBinTitle),
              ),
              findsNothing,
            );
            if (width >= 600) {
              expect(
                tester
                    .widget<NavigationRail>(find.byType(NavigationRail))
                    .destinations,
                hasLength(3),
              );
            }
            expect(find.byTooltip(fixture.copy.navMoreMenu), findsNothing);
            await _go(tester, fixture, RoutePaths.more);
            expect(find.byType(SettingsScreen), findsOneWidget);
            expect(
              find.widgetWithText(AppListTile, fixture.copy.navTemplates),
              findsNothing,
            );
            final Finder bin = find.widgetWithText(
              AppListTile,
              fixture.copy.recycleBinTitle,
            );
            expect(bin, findsOneWidget);
            await tester.ensureVisible(bin);
            await tester.tap(bin);
            await _until(
              tester,
              () => fixture.router.state.uri.path == RoutePaths.recycleBin,
            );
            expect(find.byType(RecycleBinScreen), findsOneWidget);
            expect(tester.takeException(), isNull);
            await expectNoA11yIssues(tester);
          },
        );
      }
    }
  }

  testWidgets(
    'all fitting tabs navigate directly and preserve the open project branch',
    (WidgetTester tester) async {
      final _Fixture fixture = await _pump(tester);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
        hasLength(3),
      );
      expect(find.byTooltip(fixture.copy.navMoreMenu), findsNothing);
      await _go(tester, fixture, '/projects/p1/capture');
      await tester.tap(_tab(fixture.copy.navTemplates));
      await _until(
        tester,
        () => fixture.router.state.uri.path == RoutePaths.templates,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      await tester.tap(_tab(fixture.copy.settingsTitle));
      await _until(
        tester,
        () => fixture.router.state.uri.path == RoutePaths.more,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
      await tester.tap(_tab(fixture.copy.navProjects));
      await _until(
        tester,
        () => fixture.router.state.uri.path == '/projects/p1/capture',
      );
      expect(fixture.container.read(currentProjectProvider), 'p1');
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      await _go(tester, fixture, RoutePaths.more);
      expect(tester.takeException(), isNull);
      await expectNoA11yIssues(tester);
    },
  );

  testWidgets(
    'More appears only when localized tabs overflow and lists only hidden screens',
    (WidgetTester tester) async {
      final _Fixture fixture = await _pump(
        tester,
        width: 240,
        scale: 2,
        pseudo: true,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
        hasLength(2),
      );
      final Finder more = _tab(fixture.copy.navMoreMenu);
      expect(more, meetsTapTarget());
      expect(
        find.descendant(
          of: more,
          matching: find.byIcon(AppIcons.moreHorizontal),
        ),
        findsOneWidget,
      );
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(fixture.router.state.uri.path, RoutePaths.projects);
      expect(find.byType(PopupMenuItem<int>), findsNWidgets(2));
      expect(_option(RoutePaths.projects), findsNothing);
      expect(_option(RoutePaths.recycleBin), findsNothing);
      final Material menu = tester.widget<Material>(
        find
            .ancestor(
              of: _option(RoutePaths.templates),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(
        (menu.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(Radii.md),
      );
      for (final String path in <String>[
        RoutePaths.templates,
        RoutePaths.more,
      ]) {
        expect(_option(path), meetsTapTarget());
      }
      await tester.tap(_option(RoutePaths.more));
      await _until(
        tester,
        () => fixture.router.state.uri.path == RoutePaths.more,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      final Finder bin = find.widgetWithText(
        AppListTile,
        fixture.copy.recycleBinTitle,
      );
      expect(bin, findsOneWidget);
      await tester.ensureVisible(bin);
      expect(tester.takeException(), isNull);
      await expectNoA11yIssues(tester);
    },
  );

  testWidgets(
    'resizing and Escape dismiss overflow without changing the project work screen',
    (WidgetTester tester) async {
      final _Fixture fixture = await _pump(
        tester,
        width: 240,
        scale: 2,
        pseudo: true,
      );
      await _go(tester, fixture, '/projects/p1/capture');
      await tester.tap(_tab(fixture.copy.navMoreMenu));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 100));
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuItem<int>), findsNothing);
      expect(fixture.router.state.uri.path, '/projects/p1/capture');
      await tester.tap(_tab(fixture.copy.navMoreMenu));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuItem<int>), findsNothing);
      expect(fixture.router.state.uri.path, '/projects/p1/capture');
      tester.view.physicalSize = const Size(599, 850);
      await tester.pumpAndSettle();
      expect(find.byTooltip(fixture.copy.navMoreMenu), findsNothing);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
        hasLength(3),
      );
      expect(fixture.router.state.uri.path, '/projects/p1/capture');
      tester.view.physicalSize = const Size(240, 850);
      await tester.pumpAndSettle();
      await tester.tap(_tab(fixture.copy.navMoreMenu));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(800, 850);
      await tester.pumpAndSettle();
      await tester.tap(_option(RoutePaths.templates));
      await _until(
        tester,
        () => fixture.router.state.uri.path == RoutePaths.templates,
      );
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        1,
      );
      expect(fixture.container.read(currentProjectProvider), 'p1');
      expect(tester.takeException(), isNull);
      await expectNoA11yIssues(tester);
    },
  );

  testWidgets(
    'changing locale re-evaluates tab capacity without changing the route',
    (WidgetTester tester) async {
      final _Fixture fixture = await _pump(tester, width: 320, scale: 2);
      await _go(tester, fixture, '/projects/p1/capture');
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      fixture.container
          .read(appLocaleProvider.notifier)
          .select(const Locale('en', 'XA'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationDestination), findsNWidgets(2));
      expect(fixture.router.state.uri.path, '/projects/p1/capture');
      fixture.container
          .read(appLocaleProvider.notifier)
          .select(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      expect(fixture.router.state.uri.path, '/projects/p1/capture');
      expect(tester.takeException(), isNull);
      await expectNoA11yIssues(tester);
    },
  );

  testWidgets(
    'the overflow menu supports keyboard selection and native Back dismissal',
    (WidgetTester tester) async {
      final _Fixture fixture = await _pump(
        tester,
        width: 240,
        scale: 2,
        pseudo: true,
      );
      await tester.tap(_tab(fixture.copy.navMoreMenu));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuItem<int>), findsNothing);
      expect(fixture.router.state.uri.path, RoutePaths.projects);
      await tester.tap(_tab(fixture.copy.navMoreMenu));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _until(
        tester,
        () => fixture.router.state.uri.path == RoutePaths.templates,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect(tester.takeException(), isNull);
      await expectNoA11yIssues(tester);
    },
  );
}

Finder _tab(String label) => find.widgetWithText(NavigationDestination, label);
Finder _option(String path) => find.byKey(ValueKey<String>('nav-more-$path'));
typedef _Fixture = ({
  GoRouter router,
  ProviderContainer container,
  LocalizedCopy copy,
});

Future<_Fixture> _pump(
  WidgetTester tester, {
  double width = 393,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
  bool pseudo = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 850);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  final FakeProjectRepository projects = FakeProjectRepository();
  (await projects.create(aProject(id: 'p1', name: 'Survey'))).getOrThrow();
  final FakeRecordRepository records = FakeRecordRepository();
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      networkOnlineOverride(),
      projectRepositoryProvider.overrideWithValue(projects),
      recordRepositoryProvider.overrideWithValue(records),
      projectSettingsStoreProvider.overrideWithValue(SettingsStore.fake()),
      themeModeProvider.overrideWith(
        () => ThemeModeController.withStore(TextStore.memory()),
      ),
    ],
  );
  container
      .read(appLocaleProvider.notifier)
      .select(pseudo ? const Locale('en', 'XA') : const Locale('en'));
  final GoRouter router = container.read(routerProvider);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    projects.dispose();
    records.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) =>
            MaterialApp.router(
              theme: buildTheme(brightness: Brightness.light, outdoor: false),
              locale: ref.watch(appLocaleProvider),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (BuildContext context, Widget? child) =>
                  Directionality(textDirection: direction, child: child!),
              routerConfig: router,
            ),
      ),
    ),
  );
  await _until(
    tester,
    () =>
        find.byType(NavigationBar).evaluate().isNotEmpty ||
        find.byType(NavigationRail).evaluate().isNotEmpty,
  );
  final LocalizedCopy copy = Copy.of(tester.element(find.byType(NavShell)));
  return (router: router, container: container, copy: copy);
}

Future<void> _go(WidgetTester tester, _Fixture fixture, String path) async {
  fixture.router.go(path);
  await _until(tester, () => fixture.router.state.uri.path == path);
}

Future<void> _until(WidgetTester tester, bool Function() condition) async {
  for (int attempt = 0; attempt < 30; attempt++) {
    await tester.runAsync(() => Future<void>(() {}));
    await tester.pump();
    if (condition()) {
      await tester.pumpAndSettle();
      return;
    }
  }
  expect(condition(), isTrue, reason: 'Expected navigation did not settle.');
}

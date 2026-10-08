import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/device/app_version.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/settings/presentation/about_screen.dart';

import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';

void main() {
  setUpAll(ScreenFonts.load);
  testWidgets('version, build and licences are shown', (
    WidgetTester tester,
  ) async {
    await _pump(tester, load: () async => (version: '1.0.0', build: '1'));
    await tester.pumpAndSettle();

    expect(find.text(Copy.settingsVersion), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text(Copy.settingsBuild), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text(Copy.settingsLicences), findsOneWidget);
    expect(find.text(Copy.settingsPlanLink), findsNothing);
    expect(find.text(Copy.settingsSpecLink), findsNothing);
    expect(find.textContaining('github.com'), findsNothing);
  });

  testWidgets('licences still opens its existing destination', (
    WidgetTester tester,
  ) async {
    await _pump(tester, load: () async => (version: '1.0.0', build: '7'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(Copy.settingsLicences));
    await tester.pumpAndSettle();
    expect(find.text('Licence notices'), findsOneWidget);
    expect(find.byType(AboutScreen), findsNothing);
  });

  testWidgets('the build number is the one this binary was built with', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text(appBuildNumber), findsWidgets);
  });

  testWidgets('loading renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(tester, pending: true);
    await tester.pump();
    expect(find.byType(AppSkeleton), findsOneWidget);
  });

  testWidgets('an empty snapshot renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(tester, load: () async => (version: '', build: ''));
    await tester.pumpAndSettle();
    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.settingsAboutEmptyHeadline), findsOneWidget);
  });

  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(tester, failWith: Exception('The version could not be read.'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'About keeps metadata and licences at ${cell.description}',
      (WidgetTester tester) async {
        await _pump(
          tester,
          load: () async => (version: '1.0.0', build: '7'),
          cell: cell,
        );
        await tester.pumpAndSettle();
        expect(find.text(Copy.settingsVersion), findsOneWidget);
        expect(find.text(Copy.settingsBuild), findsOneWidget);
        expect(find.text(Copy.settingsLicences), findsOneWidget);
        expect(find.text(Copy.settingsPlanLink), findsNothing);
        expect(find.text(Copy.settingsSpecLink), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(Copy.settingsLicences));
        await tester.pumpAndSettle();
        await tester.tap(find.text(Copy.settingsLicences));
        await tester.pumpAndSettle();
        expect(find.text('Licence notices'), findsOneWidget);
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
      testWidgets('About golden ${mode.$1} text$scale', (
        WidgetTester tester,
      ) async {
        await _pump(
          tester,
          load: () async => (version: '1.0.0', build: '7'),
          cell: ScreenMatrix(const Size(393, 600), scale, mode.$2, mode.$3),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/about_text${scale.toInt()}_${mode.$1}.png',
          ),
        );
      });
    }
  }
}

Future<void> _pump(
  WidgetTester tester, {
  Future<({String version, String build})> Function()? load,
  Object? failWith,
  bool pending = false,
  ScreenMatrix? cell,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = cell?.size ?? const Size(400, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext _, GoRouterState _) => const AboutScreen(),
      ),
      GoRoute(
        path: RoutePaths.settingsLicences,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('Licence notices')),
      ),
    ],
  );
  addTearDown(router.dispose);
  return tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      retry: (int _, Object _) => null,
      overrides: <Override>[
        aboutOverride(load: load, failWith: failWith, pending: pending),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: ScreenFonts.theme(
          cell?.outdoor == true
              ? buildOutdoorTheme(Brightness.light)
              : buildTheme(brightness: cell?.brightness ?? Brightness.light),
        ),
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(cell?.textScale ?? 1)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
}

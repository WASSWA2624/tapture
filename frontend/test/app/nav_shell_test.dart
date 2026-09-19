import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/nav_shell.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';

void main() {
  testWidgets('compact width uses a bottom bar', (WidgetTester tester) async {
    await _pump(tester, width: 400);

    expect(find.byKey(const ValueKey<String>('nav-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-rail')), findsNothing);
    expect(find.byKey(const ValueKey<String>('nav-pane')), findsNothing);
    expect(find.byType(NavShell), findsOneWidget);
  });

  testWidgets('medium width uses a navigation rail', (
    WidgetTester tester,
  ) async {
    await _pump(tester, width: 800);

    expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-bar')), findsNothing);
    expect(find.byKey(const ValueKey<String>('nav-pane')), findsNothing);
  });

  testWidgets('expanded width uses a rail and a list pane', (
    WidgetTester tester,
  ) async {
    await _pump(tester, width: 1200);

    expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-pane')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-bar')), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('nav-pane'))).width,
      Sizes.listPane,
    );
    expect(tester.getSize(find.byType(StatusLine)).width, 1200);
  });

  testWidgets('expanded capture and more drop the list pane', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester, width: 1200);

    router.go('/capture');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-pane')), findsNothing);

    router.go(AppRoutes.more);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-pane')), findsNothing);
    expect(find.text(Copy.navMore), findsWidgets);
    expect(find.text(Copy.operatorProfileTitle), findsOneWidget);
    expect(find.text(Copy.settingsAboutTitle), findsOneWidget);
  });

  testWidgets(
    'Capture stays larger but not accented when Projects is selected',
    (WidgetTester tester) async {
      for (final double width in <double>[400, 800, 1200]) {
        await _pump(tester, width: width);
        _expectCaptureSize(tester);
        final Icon capture = _navIcon(tester, 1);
        final Icon projects = _navIcon(tester, 0);
        expect(capture.icon, Icons.photo_camera_outlined);
        expect(projects.icon, Icons.folder);
        expect(capture.color, _unselectedInk(tester));
        expect(projects.color, _accent(tester));
        expect(<Color>{
          tester.element(find.byType(NavShell)).colors.primary,
          AppColors.dark.primary,
        }, isNot(contains(capture.color)));
      }
    },
  );

  testWidgets('Capture uses the accent and filled camera when it is selected', (
    WidgetTester tester,
  ) async {
    for (final double width in <double>[400, 800, 1200]) {
      final GoRouter router = await _pump(tester, width: width);
      router.go('/capture');
      await tester.pumpAndSettle();
      _expectCaptureSize(tester);
      final Icon capture = _navIcon(tester, 1);
      expect(capture.icon, Icons.photo_camera);
      expect(capture.color, _accent(tester));
    }
  });

  testWidgets('Projects shows a folder, filled only when it is selected', (
    WidgetTester tester,
  ) async {
    for (final double width in <double>[400, 800, 1200]) {
      final GoRouter router = await _pump(tester, width: width);
      await tester.pumpAndSettle();
      expect(_navIcon(tester, 0).icon, Icons.folder);
      router.go('/capture');
      await tester.pumpAndSettle();
      expect(_navIcon(tester, 0).icon, Icons.folder_outlined);
    }
  });

  testWidgets(
    'the stack and a half-typed field survive a switch and a width change',
    (WidgetTester tester) async {
      final GoRouter router = await _pump(tester, width: 400, projectId: 'p1');

      router.go(AppRoutes.project('p1'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('route-project')),
        findsOneWidget,
      );

      router.go(AppRoutes.records);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('route-records')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey<String>('field-records')),
        'half typed',
      );
      expect(find.text('half typed'), findsOneWidget);

      await tester.tap(_shellLabel(tester, Copy.navProjects));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.project('p1'));
      expect(
        find.byKey(const ValueKey<String>('route-project')),
        findsOneWidget,
      );

      await tester.tap(_shellLabel(tester, Copy.navRecords));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/records');
      expect(
        find.byKey(const ValueKey<String>('route-records')),
        findsOneWidget,
      );
      expect(find.text('half typed'), findsOneWidget);

      await _setWidth(tester, 800);
      expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
      expect(router.state.uri.path, '/records');
      expect(find.text('half typed'), findsOneWidget);

      await _setWidth(tester, 1200);
      expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('nav-pane')), findsOneWidget);
      expect(router.state.uri.path, '/records');
      expect(find.text('half typed'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Projects on a project home shows the list at 400, 800 and 1200dp',
    (WidgetTester tester) async {
      for (final double width in <double>[400, 800, 1200]) {
        final GoRouter router = await _pump(
          tester,
          width: width,
          projectId: 'p1',
        );
        router.go(AppRoutes.project('p1'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('route-project')),
          findsOneWidget,
        );

        await tester.tap(_shellLabel(tester, Copy.navProjects));
        await tester.pumpAndSettle();
        expect(router.state.uri.path, AppRoutes.projects);
        expect(
          find.byKey(const ValueKey<String>('route-projects')),
          findsOneWidget,
        );
      }
    },
  );
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  required double width,
  String? projectId,
}) async {
  _bindWidth(tester, width);
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [networkOnlineOverride()],
      child: const TaptureApp(),
    ),
  );
  await tester.pump();
  final BuildContext context = tester.element(find.byType(TaptureApp));
  final ProviderContainer container = ProviderScope.containerOf(context);
  if (projectId != null) {
    container.read(openProjectIdProvider.notifier).open(projectId);
    await tester.pumpAndSettle();
  }
  return container.read(routerProvider);
}

void _bindWidth(WidgetTester tester, double width) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _setWidth(WidgetTester tester, double width) async {
  _bindWidth(tester, width);
  await tester.pump();
}

Finder _shellLabel(WidgetTester tester, String label) {
  final Finder inBar = find.descendant(
    of: find.byKey(const ValueKey<String>('nav-bar')),
    matching: find.text(label),
  );
  if (inBar.evaluate().isNotEmpty) {
    return inBar;
  }
  return find.descendant(
    of: find.byKey(const ValueKey<String>('nav-rail')),
    matching: find.text(label),
  );
}

void _expectCaptureSize(WidgetTester tester) {
  expect(find.byKey(const ValueKey<String>('nav-icon-0')), findsOneWidget);
  expect(find.byKey(const ValueKey<String>('nav-icon-1')), findsOneWidget);
  expect(find.byKey(const ValueKey<String>('nav-icon-2')), findsOneWidget);
  expect(find.byKey(const ValueKey<String>('nav-icon-3')), findsOneWidget);

  final Icon capture = _navIcon(tester, 1);
  final Icon projects = _navIcon(tester, 0);
  expect(capture.size, Space.x8);
  expect(projects.size, Space.x6);
  expect(capture.size! > projects.size!, isTrue);
}

Icon _navIcon(WidgetTester tester, int index) {
  return tester.widget<Icon>(find.byKey(ValueKey<String>('nav-icon-$index')));
}

Color _accent(WidgetTester tester) {
  final BuildContext context = tester.element(find.byType(NavShell));
  return _railInverted(tester)
      ? AppColors.dark.primary
      : context.colors.primary;
}

Color _unselectedInk(WidgetTester tester) {
  final BuildContext context = tester.element(find.byType(NavShell));
  return _railInverted(tester)
      ? context.colors.surface
      : context.colors.onSurface;
}

bool _railInverted(WidgetTester tester) {
  if (find.byKey(const ValueKey<String>('nav-rail')).evaluate().isEmpty) {
    return false;
  }
  final BuildContext context = tester.element(find.byType(NavShell));
  final AppColors colors = context.colors;
  final bool outdoor =
      colors.surface == AppColors.outdoor.surface &&
      colors.onSurface == AppColors.outdoor.onSurface &&
      colors.outline == AppColors.outdoor.outline;
  return Theme.of(context).brightness == Brightness.light && !outdoor;
}

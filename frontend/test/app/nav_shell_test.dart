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
import 'package:tapture/features/onboarding/presentation/first_run_screen.dart';

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
    expect(find.text(Copy.navTemplates), findsOneWidget);
    expect(find.text(Copy.navQueue), findsOneWidget);
  });

  testWidgets('Capture is the dominant destination at 400, 800 and 1200dp', (
    WidgetTester tester,
  ) async {
    for (final double width in <double>[400, 800, 1200]) {
      await _pump(tester, width: width);
      _expectCaptureDominant(tester);
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

      await tester.enterText(
        find.byKey(const ValueKey<String>('field-project')),
        'half typed',
      );
      expect(find.text('half typed'), findsOneWidget);

      await tester.tap(_shellLabel(tester, Copy.navRecords));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/records');
      expect(
        find.byKey(const ValueKey<String>('route-records')),
        findsOneWidget,
      );

      await tester.tap(_shellLabel(tester, Copy.navProjects));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppRoutes.project('p1'));
      expect(
        find.byKey(const ValueKey<String>('route-project')),
        findsOneWidget,
      );
      expect(find.text('half typed'), findsOneWidget);

      await _setWidth(tester, 800);
      expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
      expect(router.state.uri.path, AppRoutes.project('p1'));
      expect(find.text('half typed'), findsOneWidget);

      await _setWidth(tester, 1200);
      expect(find.byKey(const ValueKey<String>('nav-rail')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('nav-pane')), findsOneWidget);
      expect(router.state.uri.path, AppRoutes.project('p1'));
      expect(find.text('half typed'), findsOneWidget);
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
      overrides: [firstRunCompletedOverride(), networkOnlineOverride()],
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

void _expectCaptureDominant(WidgetTester tester) {
  expect(find.byKey(const ValueKey<String>('nav-icon-0')), findsOneWidget);
  expect(find.byKey(const ValueKey<String>('nav-icon-1')), findsOneWidget);
  expect(find.byKey(const ValueKey<String>('nav-icon-2')), findsOneWidget);
  expect(find.byKey(const ValueKey<String>('nav-icon-3')), findsOneWidget);

  final Icon capture = tester.widget<Icon>(
    find.byKey(const ValueKey<String>('nav-icon-1')),
  );
  final Icon projects = tester.widget<Icon>(
    find.byKey(const ValueKey<String>('nav-icon-0')),
  );
  expect(capture.size, Space.x8);
  expect(projects.size, Space.x6);
  expect(capture.size! > projects.size!, isTrue);

  final BuildContext context = tester.element(find.byType(NavShell));
  expect(capture.color, context.colors.primary);
}

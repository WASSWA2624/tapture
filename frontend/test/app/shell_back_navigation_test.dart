import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/shell_back_navigation.dart';

void main() {
  late List<MethodCall> platformCalls;

  setUp(() {
    platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          platformCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  bool exited() => platformCalls.any(
    (MethodCall call) => call.method == 'SystemNavigator.pop',
  );

  for (final String root in <String>[
    RoutePaths.captureRoot,
    RoutePaths.records,
    RoutePaths.more,
  ]) {
    testWidgets('Android Back from $root visits Projects before exit', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pump(tester, location: root);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, RoutePaths.projects);
      expect(exited(), isFalse);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(exited(), isTrue);
    });
  }

  testWidgets('a cold project child visits project home then Projects', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(
      tester,
      location: RoutePaths.projectDetails('p1'),
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RoutePaths.project('p1'));
    expect(exited(), isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RoutePaths.projects);
    expect(exited(), isFalse);
  });

  testWidgets('an overlay dismisses before any branch fallback', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(tester, location: RoutePaths.records);
    unawaited(
      showDialog<void>(
        context: tester.element(find.text(RoutePaths.records)),
        builder: (BuildContext _) => const AlertDialog(title: Text('Overlay')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Overlay'), findsNothing);
    expect(router.state.uri.path, RoutePaths.records);
    expect(exited(), isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RoutePaths.projects);
  });

  testWidgets('a refused PopScope consumes native and header Back', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(
      tester,
      location: RoutePaths.captureRoot,
      root: const PopScope<void>(canPop: false, child: Text('Unsaved capture')),
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RoutePaths.captureRoot);
    expect(exited(), isFalse);
    await tester.tap(find.byKey(const ValueKey<String>('back')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RoutePaths.captureRoot);
    expect(find.text('Unsaved capture'), findsOneWidget);
  });

  testWidgets('a refused root onExit prevents the Projects fallback', (
    WidgetTester tester,
  ) async {
    bool allow = false;
    final GoRouter router = await _pump(
      tester,
      location: RoutePaths.captureRoot,
      onExit: (BuildContext _, GoRouterState _) => allow,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RoutePaths.captureRoot);
    expect(exited(), isFalse);
    allow = true;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RoutePaths.projects);
  });

  testWidgets('header Back uses the same filtered-root parent as Android', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pump(
      tester,
      location: '${RoutePaths.records}?filter=needsReview',
    );
    await tester.tap(find.byKey(const ValueKey<String>('back')));
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), RoutePaths.records);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RoutePaths.projects);
  });

  for (final TargetPlatform platform in <TargetPlatform>[
    TargetPlatform.iOS,
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  ]) {
    testWidgets(
      '$platform keeps native behavior without Android fallback',
      (WidgetTester tester) async {
        await _pump(tester, location: RoutePaths.more);
        expect(find.byType(BackButtonListener), findsNothing);
      },
      variant: TargetPlatformVariant.only(platform),
    );
  }

  testWidgets('the browser installs no native root Back listener', (
    WidgetTester tester,
  ) async {
    await _pump(tester, location: RoutePaths.more, isWeb: true);
    expect(find.byType(BackButtonListener), findsNothing);
    expect(exited(), isFalse);
  });
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  required String location,
  Widget? root,
  ExitCallback? onExit,
  bool isWeb = false,
}) async {
  final GoRouter router = GoRouter(
    initialLocation: location,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (BuildContext _, GoRouterState _, StatefulNavigationShell shell) =>
                ShellBackNavigation(
                  isWeb: isWeb,
                  child: Scaffold(
                    body: Column(
                      children: <Widget>[
                        Builder(
                          builder: (BuildContext context) => TextButton(
                            key: const ValueKey<String>('back'),
                            onPressed: () =>
                                unawaited(ShellBackNavigation.back(context)),
                            child: const Text('Back'),
                          ),
                        ),
                        Expanded(child: shell),
                      ],
                    ),
                  ),
                ),
        branches: <StatefulShellBranch>[
          for (final String path in <String>[
            RoutePaths.projects,
            RoutePaths.captureRoot,
            RoutePaths.records,
            RoutePaths.more,
          ])
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: path,
                  onExit: path == RoutePaths.captureRoot ? onExit : null,
                  builder: (BuildContext _, GoRouterState _) =>
                      path == RoutePaths.captureRoot && root != null
                      ? root
                      : Text(path),
                  routes: <RouteBase>[
                    if (path == RoutePaths.projects)
                      GoRoute(
                        path: ':projectId',
                        builder: (BuildContext _, GoRouterState state) =>
                            Text(state.uri.path),
                        routes: <RouteBase>[
                          GoRoute(
                            path: 'details',
                            builder: (BuildContext _, GoRouterState state) =>
                                Text(state.uri.path),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/widgets/status_line.dart';

import '../test/support/pump_external_work.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('browser Back and Forward retain their history order', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [networkOnlineOverride()],
        child: const TaptureApp(receiveIncomingBundles: false),
      ),
    );
    await tester.pumpAndSettle();
    final GoRouter router = ProviderScope.containerOf(
      tester.element(find.byType(TaptureApp)),
    ).read(routerProvider);
    router.go(RoutePaths.projects);
    await tester.pumpAndSettle();
    router.go(RoutePaths.more);
    await tester.pumpAndSettle();
    router.go(RoutePaths.records);
    await tester.pumpAndSettle();

    await tester.runAsync(() => _moveHistory(_window.history.back));
    await pumpExternalWork(
      tester,
      () => router.state.uri.path == RoutePaths.more,
    );
    await tester.runAsync(() => _moveHistory(_window.history.back));
    await pumpExternalWork(
      tester,
      () => router.state.uri.path == RoutePaths.projects,
    );
    await tester.runAsync(() => _moveHistory(_window.history.forward));
    await pumpExternalWork(
      tester,
      () => router.state.uri.path == RoutePaths.more,
    );
    expect(find.byType(BackButtonListener), findsNothing);
  });
}

Future<void> _moveHistory(VoidCallback move) {
  final Completer<void> changed = Completer<void>();
  late final JSFunction listener;
  listener = ((JSObject _) {
    _window.removeEventListener('popstate', listener);
    changed.complete();
  }).toJS;
  _window.addEventListener('popstate', listener);
  move();
  return changed.future;
}

@JS('window')
external _BrowserWindow get _window;

extension type _BrowserWindow._(JSObject _) implements JSObject {
  external _BrowserHistory get history;
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}

extension type _BrowserHistory._(JSObject _) implements JSObject {
  external void back();
  external void forward();
}

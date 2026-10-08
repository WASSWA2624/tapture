@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tapture/app/app.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/widgets/status_line.dart';

import '../support/pump_external_work.dart';

void main() {
  testWidgets('browser Back and Forward retain their history order', (
    WidgetTester tester,
  ) async {
    // Flutter's browser test bootstrap ignores platform messages and uses an
    // in-memory URL strategy. This test exercises the real browser history.
    ui_web.TestEnvironment.setUp(
      const ui_web.TestEnvironment(
        forceTestFonts: true,
        disableFontFallbacks: true,
        keepSemanticsDisabledOnUpdate: true,
      ),
    );
    ui_web.urlStrategy = const ui_web.HashUrlStrategy();
    addTearDown(() async {
      try {
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        ui_web.debugResetCustomUrlStrategy();
        ui_web.TestEnvironment.setUp(
          const ui_web.TestEnvironment.flutterTester(),
        );
      }
    });
    final int initialHistoryLength = _window.history.length;
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
    await pumpExternalWork(
      tester,
      () => _window.location.hash == '#${RoutePaths.records}',
    );
    expect(_window.history.length, greaterThan(initialHistoryLength));

    await tester.runAsync(() => _moveHistory(() => _window.history.back()));
    await pumpExternalWork(
      tester,
      () => router.state.uri.path == RoutePaths.more,
    );
    await tester.runAsync(() => _moveHistory(() => _window.history.back()));
    await pumpExternalWork(
      tester,
      () => router.state.uri.path == RoutePaths.projects,
    );
    await tester.runAsync(() => _moveHistory(() => _window.history.forward()));
    await pumpExternalWork(
      tester,
      () => router.state.uri.path == RoutePaths.more,
    );
    expect(find.byType(BackButtonListener), findsNothing);
  });
}

Future<void> _moveHistory(VoidCallback move) async {
  final Completer<void> changed = Completer<void>();
  final JSFunction listener = ((JSObject _) {
    if (!changed.isCompleted) changed.complete();
  }).toJS;
  _window.addEventListener('popstate', listener);
  try {
    move();
    await changed.future.timeout(const Duration(seconds: 10));
  } finally {
    _window.removeEventListener('popstate', listener);
  }
}

@JS('window')
external _BrowserWindow get _window;

extension type _BrowserWindow._(JSObject _) implements JSObject {
  external _BrowserHistory get history;
  external _BrowserLocation get location;
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}

extension type _BrowserHistory._(JSObject _) implements JSObject {
  external int get length;
  external void back();
  external void forward();
}

extension type _BrowserLocation._(JSObject _) implements JSObject {
  external String get hash;
}

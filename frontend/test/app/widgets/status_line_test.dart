import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';

void main() {
  testWidgets('every segment is a link and navigates through AppRoutes', (
    WidgetTester tester,
  ) async {
    final StreamController<NetworkState> radio = StreamController<NetworkState>(
      sync: true,
    );
    addTearDown(radio.close);
    radio.add(NetworkState.online);

    final ProviderContainer container = await _pump(
      tester,
      radio: radio,
      projectLabel: 'Alpha',
      contextLabel: 'Ward 1',
      templateLabel: 'Asset',
      unprocessed: 3,
    );
    container.read(openProjectIdProvider.notifier).open('p1');
    await tester.pumpAndSettle();

    expect(find.byType(StatusLine), findsOneWidget);
    expect(find.text(Copy.appName), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.text('Alpha · Ward 1'), findsNothing);
    expect(find.text(Copy.networkOnline), findsNothing);

    await _openOverflow(tester);
    expect(find.text('Alpha · Ward 1'), findsOneWidget);
    expect(find.text('Asset'), findsOneWidget);
    expect(find.text(Copy.networkOnline), findsOneWidget);
    expect(find.text(Copy.unprocessedCount(3)), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('status-project')),
        matching: find.byIcon(Icons.folder_outlined),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    expect(find.byIcon(Icons.wifi), findsOneWidget);
    expect(find.byIcon(Icons.pending_outlined), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('status-project')));
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).state.uri.path,
      AppRoutes.project('p1'),
    );

    await _openOverflow(tester);
    await tester.tap(find.byKey(const ValueKey<String>('status-template')));
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).state.uri.path, AppRoutes.templates);

    await _openOverflow(tester);
    await tester.tap(find.byKey(const ValueKey<String>('status-network')));
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).state.uri.path, AppRoutes.more);

    await _openOverflow(tester);
    await tester.tap(find.byKey(const ValueKey<String>('status-unprocessed')));
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).state.uri.path, AppRoutes.queue);
  });

  testWidgets('network labels distinguish radio from a chosen override', (
    WidgetTester tester,
  ) async {
    final StreamController<NetworkState> radio = StreamController<NetworkState>(
      sync: true,
    );
    addTearDown(radio.close);
    radio.add(NetworkState.online);

    await _pump(tester, radio: radio);

    await _openOverflow(tester);
    expect(find.text(Copy.networkOnline), findsOneWidget);
    await _closeOverflow(tester);

    radio.add(NetworkState.metered);
    await tester.pump();
    await _openOverflow(tester);
    expect(find.text(Copy.networkMetered), findsOneWidget);
    expect(find.byIcon(Icons.signal_cellular_alt), findsOneWidget);
    await _closeOverflow(tester);

    radio.add(NetworkState.offline);
    await tester.pump();
    await _openOverflow(tester);
    expect(find.text(Copy.networkOffline), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsWidgets);
  });

  testWidgets('offline by choice is labelled differently from the radio', (
    WidgetTester tester,
  ) async {
    final StreamController<NetworkState> radio = StreamController<NetworkState>(
      sync: true,
    );
    addTearDown(radio.close);
    radio.add(NetworkState.online);

    await _pump(tester, radio: radio, byChoice: true);

    await _openOverflow(tester);
    expect(find.text(Copy.networkOfflineByChoice), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsWidgets);
    expect(find.text(Copy.networkOnline), findsNothing);
  });
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required StreamController<NetworkState> radio,
  String? projectLabel,
  String? contextLabel,
  String? templateLabel,
  int unprocessed = 0,
  bool byChoice = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        _connectivityOverride(radio),
        offlineByChoiceOverride(byChoice),
        if (projectLabel != null)
          statusProjectLabelProvider.overrideWith((Ref _) => projectLabel),
        if (contextLabel != null)
          statusContextProvider.overrideWith((Ref _) => contextLabel),
        if (templateLabel != null)
          statusTemplateLabelProvider.overrideWith((Ref _) => templateLabel),
        unprocessedCountProvider.overrideWith((Ref _) => unprocessed),
      ],
      child: const TaptureApp(),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(TaptureApp)));
}

Future<void> _openOverflow(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('status-overflow')));
  await tester.pumpAndSettle();
}

Future<void> _closeOverflow(WidgetTester tester) async {
  await tester.tapAt(const Offset(8, 8));
  await tester.pumpAndSettle();
}

Override _connectivityOverride(StreamController<NetworkState> radio) {
  return connectivityServiceProvider.overrideWith((Ref ref) {
    final ConnectivityService service = ConnectivityService.fake(
      source: radio.stream,
    );
    ref.onDispose(service.dispose);
    return service;
  });
}

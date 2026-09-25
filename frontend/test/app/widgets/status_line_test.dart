import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/core/widgets/app_brand_lockup.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';

import '../../support/factories.dart';

void main() {
  testWidgets('operational routes remain directly linkable from settings', (
    WidgetTester tester,
  ) async {
    final StreamController<NetworkState> radio = StreamController<NetworkState>(
      sync: true,
    );
    addTearDown(radio.close);
    radio.add(NetworkState.online);

    final ProviderContainer container = await _pump(tester, radio: radio);
    await tester.pumpAndSettle();

    expect(find.byType(StatusLine), findsOneWidget);
    expect(find.text(Copy.navProjects), findsWidgets);
    expect(find.byType(AppBrandLockup), findsNothing);
    expect(find.byKey(const ValueKey<String>('status-overflow')), findsNothing);

    container.read(routerProvider).go(AppRoutes.more);
    await tester.pumpAndSettle();
    expect(find.text(Copy.navTemplates), findsNothing);
    expect(find.text(Copy.navQueue), findsNothing);

    container.read(routerProvider).go(AppRoutes.templates);
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).state.uri.path, AppRoutes.templates);

    container.read(routerProvider).go(AppRoutes.queue);
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).state.uri.path, AppRoutes.queue);
  });

  testWidgets('roots name the screen and nested routes show one back row', (
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
      openProject: aProject(id: 'p1', name: 'Alpha'),
    );
    container.read(openProjectIdProvider.notifier).open('p1');
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(StatusLine),
        matching: find.text(Copy.navProjects),
      ),
      findsOneWidget,
    );
    expect(find.byType(AppBrandLockup), findsNothing);
    expect(find.byKey(const ValueKey<String>('shell-back')), findsNothing);
    expect(find.byKey(const ValueKey<String>('status-overflow')), findsNothing);

    container.read(routerProvider).go(AppRoutes.settingsStorage);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(StatusLine),
        matching: find.text(Copy.settingsStorageTitle),
      ),
      findsOneWidget,
    );
    expect(find.text(Copy.settingsStorageTitle), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey<String>('shell-back')), findsOneWidget);
    expect(find.byType(AppBrandLockup), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('shell-back')));
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).state.uri.path, AppRoutes.more);
    expect(
      find.descendant(
        of: find.byType(StatusLine),
        matching: find.text(Copy.navMore),
      ),
      findsOneWidget,
    );
    expect(find.byType(AppBrandLockup), findsNothing);

    container.read(routerProvider).go(AppRoutes.recordsFiltered('needsReview'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(StatusLine),
        matching: find.text(Copy.navRecords),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('shell-back')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('shell-back')));
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).state.uri.path, AppRoutes.records);
    expect(
      find.descendant(
        of: find.byType(StatusLine),
        matching: find.text(Copy.navRecords),
      ),
      findsOneWidget,
    );
    expect(find.byType(AppBrandLockup), findsNothing);

    container.read(routerProvider).go(AppRoutes.project('p1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('shell-back')), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StatusLine),
        matching: find.text('Alpha'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('shell-back')));
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).state.uri.path, AppRoutes.projects);

    container.read(openProjectIdProvider.notifier).open('p1');
    container.read(routerProvider).go('${AppRoutes.project('p1')}/capture');
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(StatusLine),
        matching: find.text(Copy.navCapture),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('shell-back')));
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).state.uri.path,
      AppRoutes.project('p1'),
    );
  });

  testWidgets('create and project templates use their own titles', (
    WidgetTester tester,
  ) async {
    final StreamController<NetworkState> radio = StreamController<NetworkState>(
      sync: true,
    );
    addTearDown(radio.close);
    radio.add(NetworkState.online);
    final ProviderContainer container = await _pump(tester, radio: radio);

    container.read(routerProvider).go(AppRoutes.projectCreate);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(StatusLine),
        matching: find.text(Copy.projectCreateTitle),
      ),
      findsOneWidget,
    );
    expect(find.text(Copy.projectShowArchived), findsNothing);
    expect(find.byKey(const ValueKey<String>('shell-back')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('shell-back')));
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).state.uri.path, AppRoutes.projects);

    container.read(openProjectIdProvider.notifier).open('p1');
    container.read(routerProvider).go(AppRoutes.projectTemplates('p1'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(StatusLine),
        matching: find.text(Copy.projectTemplatesTitle),
      ),
      findsOneWidget,
    );
    expect(find.text(Copy.projectShowArchived), findsNothing);

    container.read(routerProvider).go('${AppRoutes.project('p1')}/capture');
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(StatusLine),
        matching: find.text(Copy.navCapture),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the header row stays intact at 200 percent text', (
    WidgetTester tester,
  ) async {
    final StreamController<NetworkState> radio = StreamController<NetworkState>(
      sync: true,
    );
    addTearDown(radio.close);
    radio.add(NetworkState.online);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final Size surface in <Size>[
      const Size(400, 800),
      const Size(1200, 800),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = surface;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final ProviderContainer container = await _pump(tester, radio: radio);
      container.read(routerProvider).go(AppRoutes.settingsStorage);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey<String>('shell-back')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StatusLine),
          matching: find.text(Copy.settingsStorageTitle),
        ),
        findsOneWidget,
      );
    }
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
  Project? openProject,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        _connectivityOverride(radio),
        offlineByChoiceOverride(byChoice),
        if (openProject != null)
          currentProjectDetailsProvider.overrideWith((Ref _) => openProject),
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

Override _connectivityOverride(StreamController<NetworkState> radio) {
  return connectivityServiceProvider.overrideWith((Ref ref) {
    final ConnectivityService service = ConnectivityService.fake(
      source: radio.stream,
    );
    ref.onDispose(service.dispose);
    return service;
  });
}

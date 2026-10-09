import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/app.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/shell_title.dart';
import 'package:tapture/app/widgets/status_line.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/network/network.dart';
import 'package:tapture/core/widgets/app_brand_lockup.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/shell_header_scope.dart';
import 'package:tapture/features/processing/presentation/queue_providers.dart';
import 'package:tapture/features/processing/processing.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';

import '../../support/factories.dart';

void main() {
  testWidgets('explicit header pairs override roots and nested defaults', (
    tester,
  ) async {
    final StreamController<NetworkState> radio = StreamController<NetworkState>(
      sync: true,
    );
    addTearDown(radio.close);
    final ProviderContainer container = await _pump(tester, radio: radio);
    for (final String path in <String>[
      AppRoutes.projects,
      AppRoutes.settingsStorage,
    ]) {
      container.read(routerProvider).go(path);
      await tester.pumpAndSettle();
      final BuildContext pageContext = tester.element(
        find.byType(AppPage).last,
      );
      final Object owner = Object();
      ShellHeaderScope.publish(
        pageContext,
        owner: owner,
        title: 'Screen identity',
        headerTitle: 'Field project',
        headerDetail: 'Survey template',
        actions: const <Widget>[],
        overflow: const <AppOverflowAction>[],
      );
      await tester.pumpAndSettle();
      final Finder header = find.byType(StatusLine);
      expect(
        find.descendant(of: header, matching: find.text('Field project')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.text('Survey template')),
        findsOneWidget,
      );
      ShellHeaderScope.publish(
        pageContext,
        owner: owner,
        title: 'Screen identity',
        actions: const <Widget>[],
        overflow: const <AppOverflowAction>[],
      );
      await tester.pumpAndSettle();
      expect(find.text('Survey template'), findsNothing);
      expect(
        find.descendant(
          of: header,
          matching: find.text(
            path == AppRoutes.projects ? Copy.navProjects : 'Screen identity',
          ),
        ),
        findsOneWidget,
      );
      ShellHeaderScope.release(pageContext, owner);
      await tester.pumpAndSettle();
      expect(find.text('Field project'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'legacy queue links return to Projects and transcripts remain reachable',
    (WidgetTester tester) async {
      final StreamController<NetworkState> radio =
          StreamController<NetworkState>(sync: true);
      addTearDown(radio.close);
      radio.add(NetworkState.online);

      final ProviderContainer container = await _pump(tester, radio: radio);
      await tester.pumpAndSettle();

      expect(find.byType(StatusLine), findsOneWidget);
      expect(find.text(Copy.navProjects), findsWidgets);
      expect(find.byType(AppBrandLockup), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('status-overflow')),
        findsNothing,
      );

      // From medium width up the rail's Settings lists what the compact More
      // menu offers, so nothing is reachable only on a phone.
      container.read(routerProvider).go(AppRoutes.more);
      await tester.pumpAndSettle();
      expect(find.text(Copy.navTemplates), findsOneWidget);
      expect(find.text(Copy.navQueue), findsNothing);
      expect(find.text(Copy.recycleBinTitle), findsOneWidget);
      expect(find.text(Copy.navTranscripts), findsNothing);
      container.read(routerProvider).go(RoutePaths.transcripts);
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).state.uri.path,
        RoutePaths.transcripts,
      );
      container.read(routerProvider).go(AppRoutes.more);
      await tester.pumpAndSettle();
      await tester.tap(find.text(Copy.navTemplates));
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).state.uri.path,
        AppRoutes.templates,
      );

      container.read(routerProvider).go(AppRoutes.templates);
      await tester.pumpAndSettle();
      expect(
        container.read(routerProvider).state.uri.path,
        AppRoutes.templates,
      );

      container.read(routerProvider).go(AppRoutes.queue);
      await tester.pumpAndSettle();
      expect(container.read(routerProvider).state.uri.path, AppRoutes.projects);
    },
  );

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

    container
        .read(routerProvider)
        .go(
          Uri(
            path: AppRoutes.records,
            queryParameters: <String, String>{
              AppRoutes.filterQuery: 'needsReview',
            },
          ).toString(),
        );
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

  testWidgets('offline by radio and offline by choice read differently', (
    WidgetTester tester,
  ) async {
    final StreamController<NetworkState> radio = StreamController<NetworkState>(
      sync: true,
    );
    addTearDown(radio.close);
    radio.add(NetworkState.online);
    await _pump(tester, radio: radio);
    expect(find.byKey(const ValueKey<String>('status-network')), findsNothing);

    radio.add(NetworkState.offline);
    await tester.pumpAndSettle();
    expect(find.byTooltip(Copy.networkOffline), findsOneWidget);
    expect(find.byTooltip(Copy.networkOfflineByChoice), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('status-network')),
        matching: find.byIcon(AppIcons.offline),
      ),
      findsOneWidget,
    );

    final StreamController<NetworkState> chosen =
        StreamController<NetworkState>(sync: true);
    addTearDown(chosen.close);
    chosen.add(NetworkState.offline);
    final ProviderContainer container = await _pump(
      tester,
      radio: chosen,
      byChoice: true,
    );
    expect(find.byTooltip(Copy.networkOfflineByChoice), findsOneWidget);
    expect(find.byTooltip(Copy.networkOffline), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('status-network')),
        matching: find.byIcon(AppIcons.offlineByChoice),
      ),
      findsOneWidget,
    );

    container.read(routerProvider).go(AppRoutes.records);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('status-network')));
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).state.uri.path, AppRoutes.more);
    expect(find.text(Copy.settingsOfflineTitle), findsOneWidget);
  });

  testWidgets('pending records never add a global Process badge', (
    WidgetTester tester,
  ) async {
    final StreamController<NetworkState> radio = StreamController<NetworkState>(
      sync: true,
    );
    addTearDown(radio.close);
    radio.add(NetworkState.online);
    await _pump(tester, radio: radio);
    expect(
      find.byKey(const ValueKey<String>('status-unprocessed')),
      findsNothing,
    );

    await _pump(tester, radio: radio, unprocessed: 3);
    final Finder count = find.byKey(
      const ValueKey<String>('status-unprocessed'),
    );
    expect(count, findsNothing);
    expect(find.byTooltip(Copy.unprocessedCount(3)), findsNothing);
  });

  test('the unprocessed count is the queue watch, not a stub', () async {
    final StreamController<QueueSnapshot> queue =
        StreamController<QueueSnapshot>();
    addTearDown(queue.close);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        queueSnapshotProvider.overrideWith((Ref _) => queue.stream),
      ],
    );
    addTearDown(container.dispose);
    container.listen(unprocessedCountProvider, (_, _) {});
    expect(container.read(unprocessedCountProvider), 0);

    queue.add((
      unprocessed: 7,
      queued: 2,
      failed: 0,
      requestsToday: 0,
      imagesToday: 0,
      requestCap: 0,
      groups: const <QueueGroup>[],
    ));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(unprocessedCountProvider), 7);
  });

  testWidgets('secondary destinations are titled by their own name', (
    WidgetTester tester,
  ) async {
    final StreamController<NetworkState> radio = StreamController<NetworkState>(
      sync: true,
    );
    addTearDown(radio.close);
    radio.add(NetworkState.online);
    final ProviderContainer container = await _pump(tester, radio: radio);
    final WidgetRef ref = tester.element(find.byType(StatusLine)) as WidgetRef;
    for (final ({String path, String title}) route
        in <({String path, String title})>[
          (path: AppRoutes.templates, title: Copy.navTemplates),
          (path: AppRoutes.recycleBin, title: Copy.recycleBinTitle),
          (
            path: AppRoutes.settingsAppearance,
            title: Copy.settingsAppearanceTitle,
          ),
          (path: AppRoutes.settingsRelay, title: Copy.relayTitle),
          (path: RoutePaths.settingsUploads, title: Copy.uploadHistoryTitle),
          (path: RoutePaths.projectImport, title: Copy.importTitle),
          (path: RoutePaths.transcripts, title: Copy.transcriptsTitle),
          (path: RoutePaths.transcribe, title: Copy.transcribeTitle),
          (
            path: RoutePaths.transcript('t1'),
            title: Copy.transcriptDetailTitle,
          ),
        ]) {
      expect(ShellTitle.screen(ref, Uri.parse(route.path)), route.title);
    }
    expect(
      ShellTitle.screen(ref, Uri.parse('${AppRoutes.more}/unlisted')),
      Copy.navMore,
    );
    for (final ({String path, String leaf}) route
        in <({String path, String leaf})>[
          (
            path: RoutePaths.projectTranscripts('p1'),
            leaf: Copy.transcriptsTitle,
          ),
          (
            path: RoutePaths.projectTranscribe('p1'),
            leaf: Copy.transcribeTitle,
          ),
          (
            path: RoutePaths.projectTranscript('p1', 't1'),
            leaf: Copy.transcriptDetailTitle,
          ),
        ]) {
      expect(
        ShellTitle.screen(ref, Uri.parse(route.path)),
        endsWith(' › ${route.leaf}'),
      );
    }
    expect(container.read(routerProvider), isNotNull);
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
      final ProviderContainer container = await _pump(
        tester,
        radio: radio,
        unprocessed: 120,
      );
      container.read(routerProvider).go(AppRoutes.settingsStorage);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey<String>('status-unprocessed')),
        findsNothing,
      );
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
  int unprocessed = 0,
  bool byChoice = false,
  Project? openProject,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        _connectivityOverride(radio),
        offlineByChoiceOverride(byChoice),
        if (openProject != null)
          currentProjectDetailsProvider.overrideWith((Ref _) => openProject),
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

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/backend/backend_session.dart';
import 'package:tapture/core/backend/relay_queue.dart';
import 'package:tapture/core/backend/relay_snapshot.dart';
import 'package:tapture/core/bundle/inspected_bundle.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/network/offline_now.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';
import 'package:tapture/features/account/presentation/account_session.dart';
import 'package:tapture/features/account/presentation/relay_controller.dart';
import 'package:tapture/features/account/presentation/relay_route.dart';
import 'package:tapture/features/merge/merge.dart'
    show packageImportRepositoryProvider;
import 'package:tapture/features/merge/presentation/package_import_controller.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_id_service.dart';
import '../../../support/fakes/fake_package_import_repository.dart';
import '../../../support/fakes/fake_project_repository.dart';
import '../../../support/fakes/fake_relay_server.dart';

const String _project = 'project-1';
const String _key = 'shared relay key 0123';
final DateTime _start = DateTime.utc(2026, 9, 28);

void main() {
  testWidgets(
    'entering project relay preserves disabled state and queue without egress',
    (WidgetTester tester) async {
      final List<String> requests = <String>[];
      final FakeRelayServer server = FakeRelayServer();
      final RelayQueue here = _device(server, 'device-b', requests: requests);
      await tester.runAsync(() async {
        await here.saveKey(_project, _key);
        await here.enqueue(_project, _bytes('waiting'));
      });
      final BackendSession session = await _session(
        role: 'project_manager',
        calls: requests,
      );
      final RelaySnapshot before = _value(await here.snapshot(_project));

      await _pump(
        tester,
        session: session,
        queue: here,
        routeProjectId: _project,
      );

      final RelaySnapshot after = _value(await here.snapshot(_project));
      expect(after.enabled, before.enabled);
      expect(after.queued, before.queued);
      expect(after.sent, before.sent);
      expect(after.purged, before.purged);
      expect(after.incoming, before.incoming);
      expect(after.hasKey, before.hasKey);
      expect(requests, isEmpty);
      expect(server.relayEnabled, isFalse);
      expect(_count(Copy.relayQueued, '1'), findsOneWidget);
    },
  );

  testWidgets('legacy relay with no selection offers safe project recovery', (
    WidgetTester tester,
  ) async {
    final List<String> requests = <String>[];
    final GoRouter router = await _pump(
      tester,
      session: await _session(role: 'project_manager'),
      queue: _device(FakeRelayServer(), 'device-b', requests: requests),
      selectedProjectId: null,
    );
    expect(find.text(Copy.statusNoProject), findsOneWidget);
    expect(find.byType(AppSwitchTile), findsNothing);
    await tester.tap(find.text(Copy.recordsOpenProject));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, RoutePaths.projects);
    expect(requests, isEmpty);
  });

  for (final bool legacy in <bool>[false, true]) {
    testWidgets(
      '${legacy ? 'legacy' : 'project'} relay retains its project and authority after selection changes',
      (WidgetTester tester) async {
        final FakeRelayServer server = FakeRelayServer(relayEnabled: true);
        final RelayQueue here = _device(server, 'device-b');
        await tester.runAsync(() async {
          await here.saveKey(_project, _key);
          await here.sync(_project);
        });
        final List<String> packaged = <String>[];
        await _pump(
          tester,
          session: await _session(role: 'project_manager'),
          queue: here,
          routeProjectId: legacy ? null : _project,
          overrides: <Override>[
            relayPackageProvider.overrideWith(
              (Ref _) => (String projectId) async {
                packaged.add(projectId);
                return Success<Uint8List>(_bytes('bound project'));
              },
            ),
          ],
        );
        final ProviderContainer container = ProviderScope.containerOf(
          tester.element(find.byType(RelayRoute)),
        );
        container.read(currentProjectProvider.notifier).open('other');
        await tester.pumpAndSettle();
        expect(container.read(currentProjectProvider), 'other');
        expect(find.text(Copy.relayQueueProject), findsOneWidget);
        await tester.tap(find.text(Copy.relayQueueProject));
        await _settle(tester);
        expect(packaged, <String>[_project]);
        expect(_value(await here.snapshot(_project)).queued, 1);
        expect(_value(await here.snapshot('other')).queued, 0);
        expect(server.uploads, 0);
      },
    );
  }

  testWidgets('an open key sheet stores only the route project key', (
    WidgetTester tester,
  ) async {
    final Map<SecretKey, String> vault = <SecretKey, String>{};
    final RelayQueue here = _device(
      FakeRelayServer(),
      'device-b',
      vault: vault,
    );
    await _pump(
      tester,
      session: await _session(role: 'project_manager'),
      queue: here,
      routeProjectId: _project,
    );
    await tester.tap(find.text(Copy.relayAddKey));
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(AppForm)),
    );
    container.read(currentProjectProvider.notifier).open('other');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AppForm),
        matching: find.byType(TextField),
      ),
      _key,
    );
    await tester.tap(find.text(Copy.save));
    await _settle(tester);
    final Map<String, Object?> keys =
        jsonDecode(vault[SecretKey.relayKeys]!) as Map<String, Object?>;
    expect(keys.keys, <String>[_project]);
    expect(keys[_project], _key);
  });

  testWidgets(
    'a project grant does not follow the selected project into another route',
    (WidgetTester tester) async {
      await _pump(
        tester,
        session: await _session(
          role: 'project_manager',
          grants: const <String, String?>{'other': null},
        ),
        queue: _device(FakeRelayServer(), 'device-b'),
        routeProjectId: _project,
        selectedProjectId: 'other',
      );
      expect(find.text(Copy.relaySync), findsNothing);
      expect(find.text(Copy.relayAddKey), findsNothing);
      expect(find.text(Copy.relayQueueProject), findsNothing);
    },
  );

  testWidgets(
    'queued, sent and purged counters show for the open project while offline',
    (WidgetTester tester) async {
      final FakeRelayServer server = FakeRelayServer(relayEnabled: true);
      final RelayQueue other = _device(server, 'device-a');
      final RelayQueue here = _device(server, 'device-b');
      await tester.runAsync(() async {
        await other.saveKey(_project, _key);
        await here.saveKey(_project, _key);
        await here.enqueue(_project, _bytes('sent then purged'));
        await here.sync(_project);
        await other.sync(_project);
        await other.applied(_project, server.acks.keys.single);
        await here.sync(_project);
        await here.enqueue(_project, _bytes('waiting one'));
        await here.enqueue(_project, _bytes('waiting two'));
      });
      final BackendSession session = await _session(
        role: 'field_operator',
        offline: true,
      );

      await _pump(tester, session: session, queue: here, offline: true);

      expect(_count(Copy.relayQueued, '2'), findsOneWidget);
      expect(_count(Copy.relaySent, '1'), findsOneWidget);
      expect(_count(Copy.relayPurged, '1'), findsOneWidget);
      expect(find.text(Copy.backendUnreachable), findsOneWidget);
      expect(find.text(Copy.relaySync), findsNothing);
    },
  );

  testWidgets('a never-relay project offers a project manager no way to send', (
    WidgetTester tester,
  ) async {
    final FakeRelayServer server = FakeRelayServer(
      relayEnabled: true,
      neverRelay: true,
    );
    final RelayQueue here = _device(server, 'device-b');
    await tester.runAsync(() async {
      await here.saveKey(_project, _key);
      await here.sync(_project);
    });
    final BackendSession session = await _session(role: 'project_manager');

    await _pump(tester, session: session, queue: here);

    expect(find.text(Copy.relayNever), findsOneWidget);
    expect(find.byType(AppSwitchTile), findsNothing);
    expect(find.text(Copy.relayQueueProject), findsNothing);
    expect(find.text(Copy.relaySync), findsNothing);
    expect(find.text(Copy.relayAddKey), findsNothing);
    expect(_count(Copy.relayQueued, '0'), findsOneWidget);
  });

  testWidgets(
    'a field operator on an enabled project is not offered the enable switch',
    (WidgetTester tester) async {
      final FakeRelayServer server = FakeRelayServer(relayEnabled: true);
      final RelayQueue here = _device(server, 'device-b');
      await tester.runAsync(() => here.sync(_project));
      final BackendSession session = await _session(role: 'field_operator');

      await _pump(tester, session: session, queue: here);

      expect(find.byType(AppSwitchTile), findsNothing);
      expect(find.text(Copy.relayOff), findsNothing);
      expect(find.text(Copy.relayAddKey), findsNothing);
      expect(find.text(Copy.relaySync), findsNothing);
      expect(find.text(Copy.relayQueueProject), findsNothing);
    },
  );

  testWidgets(
    'a reviewer is told relay is off until a project manager enables it and '
    'shown no control',
    (WidgetTester tester) async {
      final FakeRelayServer server = FakeRelayServer();
      final RelayQueue here = _device(server, 'device-b');
      final BackendSession session = await _session(role: 'reviewer');

      await _pump(tester, session: session, queue: here);

      expect(find.text(Copy.relayOff), findsOneWidget);
      expect(find.byType(AppSwitchTile), findsNothing);
      expect(find.text(Copy.relaySync), findsNothing);
      expect(find.text(Copy.relayAddKey), findsNothing);
    },
  );

  testWidgets(
    'turning relay on registers the project, enables it on the server and '
    'refreshes the grant',
    (WidgetTester tester) async {
      final FakeRelayServer server = FakeRelayServer();
      final RelayQueue here = _device(server, 'device-b');
      final List<String> calls = <String>[];
      // A manager's new local project is not in the grant until registered.
      final BackendSession session = await _session(
        role: 'project_manager',
        grants: const <String, String?>{},
        calls: calls,
      );

      await _pump(tester, session: session, queue: here);
      expect(find.text(Copy.relaySync), findsNothing);
      await tester.tap(find.byType(AppSwitchTile));
      await _settle(tester);

      expect(server.relayEnabled, isTrue);
      expect(calls, contains('POST /api/v1/auth/refresh'));
      expect(session.config.grants.keys, contains(_project));
      final AppSwitchTile toggle = tester.widget<AppSwitchTile>(
        find.byType(AppSwitchTile),
      );
      expect(toggle.value, isTrue);
      expect(find.text(Copy.relaySync), findsOneWidget);
    },
  );

  testWidgets(
    'a project registered to others says so instead of losing the connection',
    (WidgetTester tester) async {
      final FakeRelayServer server = FakeRelayServer()..registerStatus = 404;
      final RelayQueue here = _device(server, 'device-b');
      final BackendSession session = await _session(
        role: 'project_manager',
        grants: const <String, String?>{},
      );

      await _pump(tester, session: session, queue: here);
      await tester.tap(find.byType(AppSwitchTile));
      await _settle(tester);

      expect(server.relayEnabled, isFalse);
      expect(
        find.text('This project is registered on the server to others.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('past grant expiry says relay needs a fresh sign-in', (
    WidgetTester tester,
  ) async {
    final FakeRelayServer server = FakeRelayServer(relayEnabled: true);
    final RelayQueue here = _device(server, 'device-b');
    await tester.runAsync(() async {
      await here.saveKey(_project, _key);
      await here.sync(_project);
      await here.enqueue(_project, _bytes('held back'));
    });
    final BackendSession session = await _session(
      role: 'project_manager',
      at: _start.add(const Duration(days: 45)),
    );

    await _pump(tester, session: session, queue: here);

    expect(find.text(Copy.backendGrantExpired), findsOneWidget);
    expect(find.text(Copy.backendUnreachable), findsNothing);
    expect(find.byType(AppSwitchTile), findsNothing);
    expect(find.text(Copy.relaySync), findsNothing);
    expect(find.text(Copy.relayQueueProject), findsNothing);
    expect(_count(Copy.relayQueued, '1'), findsOneWidget);
  });

  testWidgets(
    'a device that never signed in is told to sign in and still sees its '
    'counters',
    (WidgetTester tester) async {
      final RelayQueue here = _device(FakeRelayServer(), 'device-b');
      final BackendSession session = await _session(
        role: 'field_operator',
        signedIn: false,
      );

      await _pump(tester, session: session, queue: here);

      expect(find.text(Copy.relaySignInNeeded), findsOneWidget);
      expect(_count(Copy.relayQueued, '0'), findsOneWidget);
      expect(find.text(Copy.relaySync), findsNothing);
    },
  );

  testWidgets(
    'saving the shared key keeps it on the device and offers the project '
    'queue',
    (WidgetTester tester) async {
      final FakeRelayServer server = FakeRelayServer(relayEnabled: true);
      final Map<SecretKey, String> vault = <SecretKey, String>{};
      final RelayQueue here = _device(server, 'device-b', vault: vault);
      await tester.runAsync(() => here.sync(_project));
      final BackendSession session = await _session(role: 'project_manager');

      await _pump(tester, session: session, queue: here);
      await tester.tap(find.text(Copy.relayAddKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AppForm),
          matching: find.byType(TextField),
        ),
        _key,
      );
      await tester.tap(find.text(Copy.save));
      await _settle(tester);

      expect(find.byType(AppForm), findsNothing);
      expect(vault[SecretKey.relayKeys], contains(_key));
      expect(find.text(Copy.relayAddKey), findsNothing);
      expect(find.text(Copy.relayQueueProject), findsOneWidget);
    },
  );

  testWidgets('queueing the project encrypts one package and sync sends it', (
    WidgetTester tester,
  ) async {
    final FakeRelayServer server = FakeRelayServer(relayEnabled: true);
    final RelayQueue here = _device(server, 'device-b');
    await tester.runAsync(() async {
      await here.saveKey(_project, _key);
      await here.sync(_project);
    });
    final BackendSession session = await _session(role: 'project_manager');
    final List<String> packaged = <String>[];

    await _pump(
      tester,
      session: session,
      queue: here,
      overrides: <Override>[
        relayPackageProvider.overrideWith(
          (Ref _) => (String projectId) async {
            packaged.add(projectId);
            return Success<Uint8List>(_bytes('whole project'));
          },
        ),
      ],
    );
    await tester.tap(find.text(Copy.relayQueueProject));
    await _settle(tester);

    expect(packaged, <String>[_project]);
    expect(_count(Copy.relayQueued, '1'), findsOneWidget);
    expect(server.uploads, 0);

    await tester.tap(find.text(Copy.relaySync));
    await _settle(tester);

    expect(server.uploads, 1);
    expect(server.packages.values.single, isNot(_bytes('whole project')));
    expect(_count(Copy.relayQueued, '0'), findsOneWidget);
    expect(_count(Copy.relaySent, '1'), findsOneWidget);
  });

  testWidgets(
    'a received package opens the merge preview and acknowledges only after '
    'apply',
    (WidgetTester tester) async {
      final FakeRelayServer server = FakeRelayServer(relayEnabled: true);
      final RelayQueue other = _device(server, 'device-a');
      final RelayQueue here = _device(server, 'device-b');
      final Uint8List plain = _bytes('changes from device a');
      await tester.runAsync(() async {
        await other.saveKey(_project, _key);
        await other.enqueue(_project, plain);
        await other.sync(_project);
        await here.saveKey(_project, _key);
        await here.sync(_project);
      });
      final String packageId = server.packages.keys.single;
      final BackendSession session = await _session(role: 'project_manager');
      final _Checked flow = _Checked();

      final GoRouter router = await _pump(
        tester,
        session: session,
        queue: here,
        routeProjectId: _project,
        selectedProjectId: 'other',
        overrides: <Override>[
          packageImportControllerProvider.overrideWith(() => flow),
        ],
      );
      await tester.tap(find.text(Copy.relayReceivedPackage));
      await _settle(tester);

      expect(router.state.uri.path, RoutePaths.projectMerge(_project));
      expect(flow.checked, plain);
      expect(server.acks[packageId], isNot(contains('device-b')));
      expect(server.packages.keys, contains(packageId));

      await tester.tap(find.text(_MergeStub.apply));
      await _settle(tester);

      expect(server.ackRequests, contains('device-b/$packageId'));
      expect(server.packages, isEmpty);
      final RelaySnapshot view = _value(await here.snapshot(_project));
      expect(view.incoming, isEmpty);
    },
  );

  testWidgets('the relay controls fit a phone at 200 percent text', (
    WidgetTester tester,
  ) async {
    final FakeRelayServer server = FakeRelayServer(relayEnabled: true);
    final RelayQueue here = _device(server, 'device-b');
    await tester.runAsync(() async {
      await here.saveKey(_project, _key);
      await here.sync(_project);
    });
    final BackendSession session = await _session(role: 'project_manager');
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(tester, session: session, queue: here);

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text(Copy.relaySync), 200);
    expect(find.text(Copy.relaySync), findsOneWidget);
  });
}

/// The tile titled [title] showing [value].
Finder _count(String title, String value) {
  return find.descendant(
    of: find.widgetWithText(AppListTile, title),
    matching: find.text(value),
  );
}

/// This device's or another device's queue, over its own stores.
RelayQueue _device(
  FakeRelayServer server,
  String device, {
  Map<SecretKey, String>? vault,
  List<String>? requests,
}) {
  final RelaySend send = server.sendFor(device);
  return RelayQueue(
    store: BlobStore.memory(),
    secrets: SecureStorage.fake(backing: vault ?? <SecretKey, String>{}),
    ids: FakeIdService(prefix: device.substring(device.length - 1)),
    send:
        ({
          required String method,
          required String path,
          Object? body,
          String? idempotencyKey,
        }) {
          requests?.add('$method $path');
          return send(
            method: method,
            path: path,
            body: body,
            idempotencyKey: idempotencyKey,
          );
        },
    deviceId: device,
  );
}

/// A session restored from secure storage for [role], its grant running 30
/// days from the start, read at [at]. Server calls are recorded in [calls];
/// a refresh returns the same role with the project granted.
Future<BackendSession> _session({
  required String role,
  bool offline = false,
  bool signedIn = true,
  DateTime? at,
  Map<String, String?> grants = const <String, String?>{_project: null},
  List<String>? calls,
}) async {
  final String until = _start.add(const Duration(days: 30)).toIso8601String();
  final BackendSession session = BackendSession(
    storage: SecureStorage.fake(
      backing: <SecretKey, String>{
        if (signedIn)
          SecretKey.backendSession: jsonEncode(<String, Object?>{
            'baseUrl': 'https://organisation.test',
            'accessToken': 'access',
            'refreshToken': 'refresh',
            'accountId': 'account',
            'accountEmail': 'person@example.test',
            'role': role,
            'grants': grants,
            'grantValidUntil': until,
          }),
      },
    ),
    clock: FixedClock(at ?? _start),
    deviceId: 'device-b',
    initialUrl: 'https://organisation.test',
    offline: () => offline,
    send:
        ({
          required String method,
          required String path,
          Map<String, Object?>? body,
          String? token,
        }) async {
          calls?.add('$method $path');
          if (path.endsWith('/refresh')) {
            return (
              status: 200,
              body: <String, Object?>{
                'accessToken': 'next-access',
                'refreshToken': 'next-refresh',
              },
            );
          }
          return (
            status: 200,
            body: <String, Object?>{
              'userId': 'account',
              'organisationId': 'organisation',
              'role': role,
              'grants': <Object?>[
                <String, Object?>{'projectId': _project, 'contextScope': null},
              ],
              'grantValidUntil': until,
            },
          );
        },
  );
  await session.restore();
  addTearDown(session.dispose);
  return session;
}

/// Pumps the relay page for the open project, with a merge route beside it.
Future<GoRouter> _pump(
  WidgetTester tester, {
  required BackendSession session,
  required RelayQueue queue,
  bool offline = false,
  String? routeProjectId,
  String? selectedProjectId = _project,
  List<Override> overrides = const <Override>[],
}) async {
  final FakeProjectRepository projects = FakeProjectRepository();
  _value(await projects.create(aProject(id: _project, name: 'Pumps')));
  _value(await projects.create(aProject(id: 'other', name: 'Other project')));
  addTearDown(projects.dispose);
  final GoRouter router = GoRouter(
    initialLocation: routeProjectId == null
        ? RoutePaths.settingsRelay
        : RoutePaths.projectRelay(routeProjectId),
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.settingsRelay,
        builder: (BuildContext _, GoRouterState _) => const RelayRoute(),
      ),
      GoRoute(
        path: '${RoutePaths.projects}/:projectId/settings/relay',
        builder: (BuildContext _, GoRouterState state) =>
            RelayRoute(projectId: state.pathParameters['projectId']!),
      ),
      GoRoute(
        path: RoutePaths.projects,
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('Projects')),
      ),
      GoRoute(
        path: '${RoutePaths.projects}/:projectId/merge',
        builder: (BuildContext _, GoRouterState _) => const _MergeStub(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        backendSessionProvider.overrideWith((Ref _) => session),
        relayQueueProvider.overrideWith((Ref _) => queue),
        offlineNowProvider.overrideWith((Ref _) => offline),
        projectRepositoryProvider.overrideWith((Ref _) => projects),
        projectSettingsStoreProvider.overrideWith(
          (Ref _) => SettingsStore.fake(
            stored: <String, Object?>{
              SettingKeys.openProjectId.name: selectedProjectId,
            },
          ),
        ),
        packageImportRepositoryProvider.overrideWith(
          (Ref _) => FakePackageImportRepository(),
        ),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await _settle(tester);
  return router;
}

/// Lets the queue's asynchronous stores finish, pumping frames between. A
/// busy indicator animates until the real work lands, so real time must pass
/// before the frames can settle.
Future<void> _settle(WidgetTester tester) async {
  for (int round = 0; round < 500; round++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    if (round >= 4 && !tester.binding.hasScheduledFrame) break;
  }
  await tester.pumpAndSettle();
}

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

T _value<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

/// The import flow with checking replaced: the package the relay decrypted
/// is kept for the test and opens as a small bundle for the project.
final class _Checked extends PackageImportController {
  Uint8List? checked;

  @override
  Future<Result<InspectedBundle>> check(
    PickedDocument picked, {
    String? password,
  }) async {
    checked = (picked as PickedBytes).bytes;
    return Success<InspectedBundle>(
      openedPackage(const <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[],
      }, projectId: _project),
    );
  }
}

/// Stands in for the merge preview: its apply is what a committed merge
/// reports to the import flow.
class _MergeStub extends ConsumerWidget {
  const _MergeStub();

  static const String apply = 'Apply merge';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () =>
              ref.read(packageImportControllerProvider.notifier).applied(),
          child: const Text(apply),
        ),
      ),
    );
  }
}

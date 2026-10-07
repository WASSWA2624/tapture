import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/device/device_identity.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/ids/ids.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/merge/merge.dart';
import 'package:tapture/features/merge/presentation/package_import_controller.dart';
import 'package:tapture/features/merge/presentation/package_import_flow.dart';

import '../../../support/bundle_fixture.dart';
import '../../../support/fakes/fake_package_import_repository.dart';

void main() {
  late Uint8List package;
  late String projectId;

  setUpAll(() async {
    final BundleFixture fixture = await seedProjectForBundle();
    projectId = fixture.projectId;
    final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 27, 9));
    final Result<BundleOutput> written = await BundleWriter(
      db: fixture.db,
      storageRoot: fixture.storageRoot,
      files: FileReader(storageRoot: fixture.storageRoot),
      clock: clock,
      ids: UuidV7Service.sequence(clock),
      deviceId: 'device-test',
      device: () async => const DeviceDescriptor.fake(),
      inBrowser: false,
    ).write(projectId: projectId, cancel: CancellationToken());
    final StoredBundle stored =
        (written as Success<BundleOutput>).value as StoredBundle;
    package = File(
      '${fixture.root.path}/${stored.relativePath}',
    ).readAsBytesSync();
    await fixture.db.close();
    fixture.root.parent.deleteSync(recursive: true);
  });

  testWidgets('a project unknown here shows what the package holds and '
      'imports as a new project', (WidgetTester tester) async {
    final FakePackageImportRepository repository =
        FakePackageImportRepository();
    final GoRouter router = await _pump(tester, repository, package);

    await _start(tester);
    expect(find.text(Copy.importSheetTitle), findsOneWidget);
    expect(find.text('Seeded project'), findsOneWidget);
    expect(find.byKey(importMergeIntoKey), findsOneWidget);

    await tester.tap(find.byKey(importAsNewKey));
    await tester.pumpAndSettle();
    expect(repository.imported, <String>[projectId]);
    expect(router.state.uri.path, '/projects/$projectId');
    expect(find.text(Copy.importDone(2)), findsOneWidget);
  });

  test('cancelling inspection cannot close a subsequent package', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final PackageImportController flow = container.read(
      packageImportControllerProvider.notifier,
    );
    final Future<Result<InspectedBundle>> first = flow.check(
      PickedBytes(package, 'first.zip'),
    );
    await flow.finish();
    final Future<Result<InspectedBundle>> second = flow.check(
      PickedBytes(package, 'second.zip'),
    );
    expect(await first, isA<FailureResult<InspectedBundle>>());
    final InspectedBundle active = (await second).getOrThrow();
    expect(
      container.read(packageImportControllerProvider).bundle,
      same(active),
    );
    await flow.finish();
  });

  test(
    'disposing an inspection closes its late reader and releases only its copy',
    () async {
      final Directory root = await Directory.systemTemp.createTemp(
        'import-disposal-',
      );
      final File original = File('${root.path}/original.zip');
      final File copied = File('${root.path}/copy.zip');
      await original.writeAsBytes(package);
      await copied.writeAsBytes(package);
      final ProviderContainer container = ProviderContainer();
      final PackageImportController flow = container.read(
        packageImportControllerProvider.notifier,
      );
      final Future<Result<InspectedBundle>> inspecting = flow.check(
        PickedFile(copied, 'copy.zip', package.length, isCopy: true),
      );
      container.dispose();
      expect(await inspecting, isA<FailureResult<InspectedBundle>>());
      final Stopwatch timeout = Stopwatch()..start();
      while (await copied.exists()) {
        if (timeout.elapsed > const Duration(seconds: 10)) {
          fail('Reader did not release its copy');
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(await original.readAsBytes(), package);
      await root.delete(recursive: true);
    },
  );

  testWidgets('a project deleted here is refused', (WidgetTester tester) async {
    final FakePackageImportRepository repository = FakePackageImportRepository(
      presence: PackagePresence.deleted,
    );
    final GoRouter router = await _pump(tester, repository, package);

    await _start(tester);
    expect(find.text(Copy.importProjectDeletedHere), findsOneWidget);
    expect(find.text(Copy.importSheetTitle), findsNothing);
    expect(repository.imported, isEmpty);
    expect(router.state.uri.path, '/start');
  });

  testWidgets('a project live here goes to its merge preview', (
    WidgetTester tester,
  ) async {
    final FakePackageImportRepository repository = FakePackageImportRepository(
      presence: PackagePresence.live,
    );
    final GoRouter router = await _pump(tester, repository, package);

    await _start(tester);
    expect(router.state.uri.path, '/projects/$projectId/merge');
  });

  testWidgets('a file that is not a package is refused, naming the check', (
    WidgetTester tester,
  ) async {
    final FakePackageImportRepository repository =
        FakePackageImportRepository();
    await _pump(
      tester,
      repository,
      Uint8List.fromList(List<int>.filled(64, 7)),
    );

    await _start(tester);
    expect(
      find.text(BundleReader.rejectionMessage(BundleRejection.notAPackage)),
      findsOneWidget,
    );
    expect(find.text(Copy.importSheetTitle), findsNothing);
  });
}

Future<void> _start(WidgetTester tester) async {
  await tester.tap(find.text('import'));
  for (int round = 0; round < 50; round++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<GoRouter> _pump(
  WidgetTester tester,
  FakePackageImportRepository repository,
  Uint8List bytes,
) async {
  final GoRouter router = GoRouter(
    initialLocation: '/start',
    routes: <RouteBase>[
      GoRoute(
        path: '/start',
        builder: (BuildContext _, GoRouterState _) => Scaffold(
          body: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              return TextButton(
                onPressed: () => startPackageImport(context, ref),
                child: const Text('import'),
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: '/projects/:projectId',
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('project home')),
        routes: <RouteBase>[
          GoRoute(
            path: 'merge',
            builder: (BuildContext _, GoRouterState _) =>
                const Scaffold(body: Text('merge preview')),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        packageImportRepositoryProvider.overrideWith((Ref _) => repository),
        documentPickerProvider.overrideWith(
          (Ref _) =>
              DocumentPicker.fake(document: PickedBytes(bytes, 'pumps.zip')),
        ),
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

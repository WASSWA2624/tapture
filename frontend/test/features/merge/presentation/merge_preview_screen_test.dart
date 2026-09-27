import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/bundle/inspected_bundle.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/merge/domain/domain.dart';
import 'package:tapture/features/merge/presentation/conflict_screen.dart';
import 'package:tapture/features/merge/presentation/duplicate_pair_sheet.dart';
import 'package:tapture/features/merge/presentation/merge_controller.dart';
import 'package:tapture/features/merge/presentation/merge_preview_screen.dart';
import 'package:tapture/features/merge/presentation/merge_target_sheet.dart';
import 'package:tapture/features/merge/presentation/merge_view.dart';
import 'package:tapture/features/merge/presentation/package_import_controller.dart';
import 'package:tapture/features/merge/presentation/package_import_phase.dart';
import 'package:tapture/features/merge/merge.dart';
import 'package:tapture/features/projects/projects.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_package_import_repository.dart';
import '../../projects/fakes/fake_project_repository.dart';

/// Tables as a package carries them.
typedef Tables = Map<String, List<Map<String, Object?>>>;

void main() {
  Map<String, Object?> template(String id, {String key = 'pump'}) =>
      <String, Object?>{
        'id': id,
        'name': 'Pump check',
        'version': 1,
        'detection': jsonEncode(<String, Object?>{'template_key': key}),
      };

  Map<String, Object?> field(String template) => <String, Object?>{
    'id': '$template-serial',
    'template_id': template,
    'field_key': 'serial',
    'label': 'Serial',
    'type': 'text',
    'required': 0,
    'options': '[]',
  };

  Map<String, Object?> record(String id, {String template = 't1'}) =>
      <String, Object?>{
        'id': id,
        'project_id': 'p1',
        'template_id': template,
        'status': 'captured',
        'updated_at': 100,
      };

  Map<String, Object?> value(String record, String finalValue) =>
      <String, Object?>{
        'id': 'v-$record',
        'record_id': record,
        'field_key': 'serial',
        'value_raw': 'raw',
        'value_final': finalValue,
        'verified': 0,
        'source': 'TYPED',
        'rev': 2,
        'updated_at': 100,
        'updated_by_device': 'device',
      };

  Map<String, Object?> caption(String record, String text) => <String, Object?>{
    'id': 'c-$record',
    'owner_type': 'record',
    'owner_id': record,
    'text_raw': text,
  };

  Map<String, Object?> photo(String record, String sha) => <String, Object?>{
    'id': 'ph-$record',
    'project_id': 'p1',
    'record_id': record,
    'relative_path': 'photos/$record.jpg',
    'sha256': sha,
  };

  /// This device: record r1, its value 'C', one photo.
  Tables here() => <String, List<Map<String, Object?>>>{
    'templates': <Map<String, Object?>>[template('t1')],
    'template_fields': <Map<String, Object?>>[field('t1')],
    'records': <Map<String, Object?>>[record('r1')],
    'record_fields': <Map<String, Object?>>[value('r1', 'C')],
    'captions': <Map<String, Object?>>[caption('r1', 'Pump one')],
    'photos': <Map<String, Object?>>[photo('r1', 'sha-1')],
  };

  /// The package: r1 with 'B', and a new record r2 holding r1's photo.
  Tables incoming({List<String> changed = const <String>['r1']}) =>
      <String, List<Map<String, Object?>>>{
        'templates': <Map<String, Object?>>[template('t1')],
        'template_fields': <Map<String, Object?>>[field('t1')],
        'records': <Map<String, Object?>>[
          for (final String id in changed) record(id),
          record('r2'),
        ],
        'record_fields': <Map<String, Object?>>[
          for (final String id in changed) value(id, 'B'),
        ],
        'captions': <Map<String, Object?>>[caption('r2', 'Pump two')],
        'photos': <Map<String, Object?>>[photo('r2', 'sha-1')],
      };

  testWidgets('the preview reports the templates and counts, a conflict is '
      'settled one at a time, then Merge applies the choice', (
    WidgetTester tester,
  ) async {
    final FakePackageImportRepository repository = FakePackageImportRepository(
      local: <String, Tables>{'p1': here()},
    );
    final GoRouter router = await _pump(
      tester,
      repository,
      openedPackage(incoming()),
    );

    expect(find.text('Pump check'), findsOneWidget);
    expect(find.text(Copy.compatibilityStatus('compatible')), findsOneWidget);
    expect(find.text(Copy.mergeCount('newRecords', 1)), findsOneWidget);
    expect(find.text(Copy.mergeCount('conflicts', 1)), findsOneWidget);
    expect(find.text(Copy.mergeSettleConflicts(1)), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('merge-count-newRecords')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pump two'), findsOneWidget);

    await tester.tap(find.byKey(MergePreviewScreen.applyKey));
    await tester.pumpAndSettle();
    expect(find.text(Copy.conflictProgress(1, 1)), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    await tester.tap(find.byKey(ConflictScreen.takeIncomingKey));
    await tester.pumpAndSettle();
    expect(find.text(Copy.mergeApply), findsOneWidget);
    expect(repository.merges, isEmpty, reason: 'a choice writes nothing');

    await tester.tap(find.byKey(MergePreviewScreen.applyKey));
    await _until(tester, () => repository.merges.isNotEmpty);
    await tester.pumpAndSettle();
    final FieldConflict conflict =
        repository.merges.single.plan.conflicts.single;
    expect(repository.merges.single.choices, <String, ConflictChoice>{
      conflict.id: ConflictChoice.theirs,
    });
    expect(router.state.uri.path, '/projects/p1');
  });

  testWidgets('Cancel leaves without writing', (WidgetTester tester) async {
    final FakePackageImportRepository repository = FakePackageImportRepository(
      local: <String, Tables>{'p1': here()},
    );
    final GoRouter router = await _pump(
      tester,
      repository,
      openedPackage(incoming()),
    );
    await tester.tap(find.byKey(MergePreviewScreen.cancelKey));
    await tester.pumpAndSettle();
    expect(repository.merges, isEmpty);
    expect(router.state.uri.path, '/projects/p1');
  });

  testWidgets('both bulk choices confirm with their count and settle every '
      'conflict', (WidgetTester tester) async {
    for (final (Key bulk, ConflictChoice expected) in <(Key, ConflictChoice)>[
      (ConflictScreen.takeAllKey, ConflictChoice.theirs),
      (ConflictScreen.keepAllKey, ConflictChoice.mine),
    ]) {
      final Tables local = here()
        ..['records']!.add(record('r3'))
        ..['record_fields']!.add(value('r3', 'C'));
      final FakePackageImportRepository repository =
          FakePackageImportRepository(local: <String, Tables>{'p1': local});
      await _pump(
        tester,
        repository,
        openedPackage(incoming(changed: <String>['r1', 'r3'])),
      );
      expect(find.text(Copy.mergeSettleConflicts(2)), findsOneWidget);
      await tester.tap(find.byKey(MergePreviewScreen.applyKey));
      await tester.pumpAndSettle();
      expect(find.text(Copy.conflictProgress(1, 2)), findsOneWidget);

      await tester.tap(find.byKey(bulk));
      await tester.pumpAndSettle();
      expect(
        find.text(
          Copy.mergeBulkConfirm(2, incoming: expected == ConflictChoice.theirs),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find
            .text(
              expected == ConflictChoice.theirs
                  ? Copy.conflictTakeIncoming
                  : Copy.conflictKeepMine,
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(find.text(Copy.mergeApply), findsOneWidget);

      await tester.tap(find.byKey(MergePreviewScreen.applyKey));
      await _until(tester, () => repository.merges.isNotEmpty);
      await tester.pumpAndSettle();
      expect(repository.merges.single.choices.values.toSet(), <ConflictChoice>{
        expected,
      });
      expect(repository.merges.single.choices, hasLength(2));
    }
  });

  testWidgets('a package that holds nothing new says so and cannot merge', (
    WidgetTester tester,
  ) async {
    final FakePackageImportRepository repository = FakePackageImportRepository(
      local: <String, Tables>{'p1': here()},
    );
    await _pump(tester, repository, openedPackage(here()));
    expect(find.text(Copy.mergeNothing), findsOneWidget);
    expect(_applyEnabled(tester), isFalse);
  });

  testWidgets('a package whose templates do not fit names why and cannot '
      'merge', (WidgetTester tester) async {
    final Tables local = <String, List<Map<String, Object?>>>{
      'templates': <Map<String, Object?>>[template('t9', key: 'meter')],
      'template_fields': <Map<String, Object?>>[field('t9')],
    };
    final FakePackageImportRepository repository = FakePackageImportRepository(
      local: <String, Tables>{'p1': local},
    );
    await _pump(tester, repository, openedPackage(incoming(), projectId: 'p9'));
    expect(find.text(Copy.compatibilityStatus('incompatible')), findsOneWidget);
    expect(find.text(Copy.compatibilityIssue('noMatch', '')), findsOneWidget);
    expect(find.text(Copy.mergeBlocked), findsOneWidget);
    expect(_applyEnabled(tester), isFalse);
  });

  testWidgets('a possible duplicate can be left out, and the check off finds '
      'nothing', (WidgetTester tester) async {
    final FakePackageImportRepository repository = FakePackageImportRepository(
      local: <String, Tables>{'p1': here()},
    );
    final Tables package = incoming(changed: const <String>[]);
    await _pump(tester, repository, openedPackage(package));
    expect(find.text(Copy.mergeCount('duplicates', 1)), findsOneWidget);
    expect(find.text(Copy.mergeCount('newRecords', 1)), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('merge-count-duplicates')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('merge-duplicate-r2')));
    await tester.pumpAndSettle();
    expect(find.text(Copy.duplicateSignal('photo')), findsWidgets);
    expect(find.text('Pump one'), findsOneWidget);

    await tester.tap(find.byKey(duplicateSkipKey));
    await _until(
      tester,
      () => find.text(Copy.mergeCount('newRecords', 0)).evaluate().isNotEmpty,
    );
    expect(find.text(Copy.duplicateSkipped), findsOneWidget);

    await tester.tap(find.byKey(MergePreviewScreen.duplicatesKey));
    await _until(
      tester,
      () => find.text(Copy.mergeCount('newRecords', 1)).evaluate().isNotEmpty,
    );
    expect(find.text(Copy.mergeCount('duplicates', 1)), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('merge-count-duplicates')),
      findsNothing,
    );

    await tester.tap(find.byKey(MergePreviewScreen.applyKey));
    await _until(tester, () => repository.merges.isNotEmpty);
    expect(repository.merges.single.duplicates, isEmpty);
    expect(repository.merges.single.skipped, isEmpty);
  });

  testWidgets('the target sheet orders projects by fit, and one that does '
      'not fit cannot be chosen', (WidgetTester tester) async {
    final FakeProjectRepository projects = FakeProjectRepository();
    addTearDown(projects.dispose);
    for (final (String id, String name) in <(String, String)>[
      ('p-meters', 'A meters project'),
      ('p-pumps', 'Z pumps project'),
    ]) {
      await projects.create(aProject(id: id, name: name));
    }
    final FakePackageImportRepository repository = FakePackageImportRepository(
      local: <String, Tables>{
        'p-pumps': <String, List<Map<String, Object?>>>{
          'templates': <Map<String, Object?>>[template('t-here')],
          'template_fields': <Map<String, Object?>>[field('t-here')],
        },
        'p-meters': <String, List<Map<String, Object?>>>{
          'templates': <Map<String, Object?>>[template('t-m', key: 'meter')],
        },
      },
    );
    String? chosen = 'none';
    await tester.pumpWidget(
      ProviderScope(
        retry: (int _, Object _) => null,
        overrides: <Override>[
          packageImportRepositoryProvider.overrideWith((Ref _) => repository),
          projectRepositoryProvider.overrideWith((Ref _) => projects),
          packageImportControllerProvider.overrideWith(
            () => _Opened(openedPackage(incoming(), projectId: 'p-away')),
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  chosen = await showMergeTargetSheet(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final double pumps = tester.getTopLeft(find.text('Z pumps project')).dy;
    final double meters = tester.getTopLeft(find.text('A meters project')).dy;
    expect(pumps, lessThan(meters), reason: 'compatible first');
    expect(find.text(Copy.compatibilityIssue('noMatch', '')), findsOneWidget);

    await tester.tap(find.text('A meters project'));
    await tester.pumpAndSettle();
    expect(chosen, 'none', reason: 'a blocked project cannot be chosen');

    await tester.tap(find.text('Z pumps project'));
    await tester.pumpAndSettle();
    expect(chosen, 'p-pumps');
  });
}

/// The import flow with [bundle] already open.
final class _Opened extends PackageImportController {
  _Opened(this.bundle);

  final InspectedBundle bundle;

  @override
  PackageImportView build() =>
      (phase: PackageImportPhase.ready, bundle: bundle, progress: 0);
}

Future<GoRouter> _pump(
  WidgetTester tester,
  FakePackageImportRepository repository,
  InspectedBundle bundle,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 2400);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final GoRouter router = GoRouter(
    initialLocation: '/projects/p1/merge',
    routes: <RouteBase>[
      GoRoute(
        path: '/projects/:projectId',
        builder: (BuildContext _, GoRouterState _) =>
            const Scaffold(body: Text('project home')),
        routes: <RouteBase>[
          GoRoute(
            path: 'merge',
            builder: (BuildContext _, GoRouterState state) =>
                MergePreviewScreen(
                  projectId: state.pathParameters['projectId']!,
                ),
            routes: <RouteBase>[
              GoRoute(
                path: 'conflicts',
                builder: (BuildContext _, GoRouterState state) =>
                    ConflictScreen(
                      projectId: state.pathParameters['projectId']!,
                      conflictId: state.uri.queryParameters['conflict'],
                    ),
              ),
            ],
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
        packageImportControllerProvider.overrideWith(() => _Opened(bundle)),
      ],
      child: MaterialApp.router(
        theme: buildTheme(brightness: Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await _until(tester, () {
    final AsyncValue<MergeView?> value = ProviderScope.containerOf(
      tester.element(find.byType(MergePreviewScreen)),
    ).read(mergeControllerProvider('p1'));
    return value.hasValue && !value.isLoading;
  });
  await tester.pumpAndSettle();
  return router;
}

/// Lets real isolates finish, pumping frames until [done].
Future<void> _until(WidgetTester tester, bool Function() done) async {
  for (int round = 0; round < 200 && !done(); round++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
  expect(done(), isTrue, reason: 'the merge never finished planning');
}

bool _applyEnabled(WidgetTester tester) {
  final Finder button = find.descendant(
    of: find.byKey(MergePreviewScreen.applyKey),
    matching: find.byWidgetPredicate(
      (Widget widget) => widget is ButtonStyleButton,
    ),
  );
  return tester.widget<ButtonStyleButton>(button.first).onPressed != null;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/bundle/inspected_bundle.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/merge/domain/domain.dart';
import 'package:tapture/features/merge/merge.dart';
import 'package:tapture/features/merge/presentation/merge_controller.dart';
import 'package:tapture/features/merge/presentation/merge_view.dart';
import 'package:tapture/features/merge/presentation/package_import_controller.dart';
import 'package:tapture/features/merge/presentation/package_import_phase.dart';

import '../../../support/fakes/fake_package_import_repository.dart';

void main() {
  Map<String, Object?> record(int updatedAt) => <String, Object?>{
    'id': 'r1',
    'project_id': 'p1',
    'template_id': 't1',
    'status': 'captured',
    'updated_at': updatedAt,
    'updated_by_device': 'device-a',
  };

  testWidgets('a record deleted there but changed here shows both sides, '
      'and keeping it settles the conflict without writing', (
    WidgetTester tester,
  ) async {
    final FakePackageImportRepository repository = FakePackageImportRepository(
      local: <String, Map<String, List<Map<String, Object?>>>>{
        'p1': <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record(300)],
        },
      },
    );
    final InspectedBundle bundle = openedPackage(
      <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[record(100)],
        'tombstones': <Map<String, Object?>>[
          <String, Object?>{
            'id': 'tomb-r1',
            'entity_type': 'records',
            'entity_id': 'r1',
            'deleted_at': 200,
            'deleted_by_device': 'device-b',
          },
        ],
      },
    );
    final GoRouter router = GoRouter(
      initialLocation: '/merge/conflicts',
      routes: <RouteBase>[
        GoRoute(
          path: '/merge',
          builder: (BuildContext _, GoRouterState _) =>
              const Scaffold(body: Text('preview')),
          routes: <RouteBase>[
            GoRoute(
              path: 'conflicts',
              builder: (BuildContext _, GoRouterState _) =>
                  const ConflictScreen(projectId: 'p1'),
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
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(ConflictScreen)),
    );
    // Held open, so the merge outlives the screen as the preview's would.
    final ProviderSubscription<AsyncValue<MergeView?>> merge = container.listen(
      mergeControllerProvider('p1'),
      (_, _) {},
    );
    addTearDown(merge.close);
    for (int round = 0; round < 200; round++) {
      final AsyncValue<MergeView?> value = merge.read();
      if (value.hasValue && !value.isLoading) {
        break;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text(Copy.conflictProgress(1, 1)), findsOneWidget);
    expect(find.text(Copy.conflictDeletion('deletedThere')), findsOneWidget);
    expect(find.text(Copy.conflictChanged), findsOneWidget);
    expect(find.text(Copy.conflictDeleted), findsOneWidget);
    expect(find.byKey(ConflictScreen.keepAllKey), findsNothing);

    await tester.tap(find.byKey(ConflictScreen.keepMineKey));
    await tester.pumpAndSettle();

    final MergeView view = merge.read().requireValue!;
    expect(view.unsettled, isEmpty);
    expect(view.choices.values.single, ConflictChoice.mine);
    expect(router.state.uri.path, '/merge');
    expect(repository.merges, isEmpty);
  });
}

final class _Opened extends PackageImportController {
  _Opened(this.bundle);

  final InspectedBundle bundle;

  @override
  PackageImportView build() =>
      (phase: PackageImportPhase.ready, bundle: bundle, progress: 0);
}

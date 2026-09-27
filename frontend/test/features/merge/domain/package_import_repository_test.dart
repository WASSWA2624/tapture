import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/merge/domain/domain.dart';
import 'package:tapture/features/quality/quality.dart';

import '../../../support/fakes/fake_package_import_repository.dart';

/// The port's contract, held by the fake every screen test uses; the Drift
/// implementation is held to the same in `package_import_repository_impl_test`.
void main() {
  final Map<String, List<Map<String, Object?>>> tables =
      <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[
          <String, Object?>{'id': 'r1', 'template_id': 't1', 'status': 'a'},
        ],
      };

  test(
    'a merge with an unsettled conflict is refused and writes nothing',
    () async {
      final FakePackageImportRepository repository =
          FakePackageImportRepository(
            local: <String, Map<String, List<Map<String, Object?>>>>{
              'p1': <String, List<Map<String, Object?>>>{
                'records': <Map<String, Object?>>[
                  <String, Object?>{
                    'id': 'r1',
                    'template_id': 't1',
                    'status': 'b',
                  },
                ],
              },
            },
          );
      final MergeGround ground = _ok(
        await repository.groundFor(projectId: 'p1', incoming: tables),
      );
      final MergePlan plan = MergePlanner.plan(
        incoming: tables,
        local: ground.local,
        templateMapping: const <String, String>{'t1': 't1'},
        targetProjectId: 'p1',
        incomingProjectId: 'p1',
      );
      expect(plan.conflicts, hasLength(1));
      final Result<MergeOutcome> refused = await repository.merge(
        bundle: openedPackage(tables),
        projectId: 'p1',
        plan: plan,
        choices: const <String, ConflictChoice>{},
        duplicates: const <PossibleDuplicate>[],
        skipped: const <String>{},
        chooser: 'Ada',
      );
      expect(refused, isA<FailureResult<MergeOutcome>>());
      expect(repository.merges, isEmpty);

      final MergeOutcome merged = _ok(
        await repository.merge(
          bundle: openedPackage(tables),
          projectId: 'p1',
          plan: plan,
          choices: <String, ConflictChoice>{
            plan.conflicts.single.id: ConflictChoice.mine,
          },
          duplicates: const <PossibleDuplicate>[],
          skipped: const <String>{},
          chooser: 'Ada',
        ),
      );
      expect(merged.records, 0);
      expect(repository.merges.single.chooser, 'Ada');
    },
  );

  test('an import reports the project it brought and its records', () async {
    final FakePackageImportRepository repository =
        FakePackageImportRepository();
    final ImportedProject imported = _ok(
      await repository.importAsNew(openedPackage(tables, projectId: 'p7')),
    );
    expect(imported, (projectId: 'p7', records: 1));
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/records.dart';

import '../fakes/record_results.dart';

void main() {
  group('the default record store, before main wires the database', () {
    late ProviderContainer container;
    late RecordRepository repo;

    setUp(() {
      container = ProviderContainer();
      repo = container.read(recordRepositoryProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('reads nothing and never fails a read', () async {
      expect(await repo.watchEntry('r1').first, isNull);
      expect(okOf(await repo.byId('r1')), isNull);
      expect(
        await repo
            .watchPage(
              'p1',
              filter: RecordFilter.none,
              sort: RecordSort.newestFirst,
              offset: 0,
              limit: 50,
            )
            .first,
        isEmpty,
      );
      expect(await repo.watchCount('p1', RecordFilter.none).first, 0);
      expect(okOf(await repo.facets('p1')).isEmpty, isTrue);
      expect(await repo.watchHistory('r1').first, isEmpty);
      expect(await repo.watchBin().first, isEmpty);
    });

    test('refuses every write with a storage failure that says why', () async {
      final List<Result<Object?>> writes = <Result<Object?>>[
        await repo.save((
          projectId: 'p1',
          templateId: 't1',
          fields: const <String, String>{},
          context: const <String, String>{},
        )),
        await repo.transition('r1', RecordStatus.approved),
        await repo.editValues('r1', const <RecordValueEdit>[
          (fieldKey: 'serial', value: 'A1'),
        ]),
        await repo.planTemplateChange('r1', 't2'),
        await repo.changeTemplate('r1', 't2'),
        await repo.delete('r1', reason: 'Deleted by the operator.'),
        await repo.restore('r1'),
      ];
      for (final Result<Object?> written in writes) {
        final Failure failure = failureOf(written);
        expect(failure, isA<StorageFailure>());
        expect(failure.message, 'Records are not available yet.');
        expect(failure.recoveryAction, isNotEmpty);
      }
    });

    test('is one instance for the life of the scope', () {
      expect(container.read(recordRepositoryProvider), same(repo));
    });
  });
}

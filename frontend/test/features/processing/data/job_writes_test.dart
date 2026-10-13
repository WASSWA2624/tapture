import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/processing/data/job_writes.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';

import '../../../support/processing_fixture.dart';

void main() {
  late ProcessingFixture fixture;
  late ProcessingJob job;
  late JobWrites writes;

  setUp(() async {
    fixture = await ProcessingFixture.open();
    job = await fixture.job();
    writes = JobWrites(db: fixture.db);
  });

  test(
    'superseded stages cannot change or read the newer job metadata',
    () async {
      await fixture.db
          .update(fixture.db.processing)
          .write(
            const ProcessingCompanion(
              requestGeneration: Value<int>(1),
              provider: Value<String>('current-provider'),
              model: Value<String>('current-model'),
              skipReason: Value<String>('current-skip'),
              lastError: Value<String>('current-error'),
              rejections: Value<String>('["current-finding"]'),
            ),
          );
      final ProcessingJobRow before = await fixture.db
          .select(fixture.db.processing)
          .getSingle();
      final List<Future<void> Function()> operations =
          <Future<void> Function()>[
            () => writes.setSkip(job.id, 'old-skip', expectedGeneration: 0),
            () => writes.setProvider(
              job.id,
              provider: 'old-provider',
              model: 'old-model',
              expectedGeneration: 0,
            ),
            () => writes.setQueueMessage(
              job.id,
              'old-error',
              expectedGeneration: 0,
            ),
            () => writes.appendRejections(job.id, <String>[
              'old-finding',
            ], expectedGeneration: 0),
            () async {
              await writes.rejections(job.id, expectedGeneration: 0);
            },
            () => writes.requireGeneration(job.id, 0),
          ];
      for (final Future<void> Function() operation in operations) {
        await expectLater(operation(), throwsA(isA<CancelledFailure>()));
        final ProcessingJobRow current = await fixture.db
            .select(fixture.db.processing)
            .getSingle();
        expect(current.toJson(), before.toJson());
      }
    },
  );

  test(
    'the current attempt writes metadata and retains concurrent findings',
    () async {
      await writes.setSkip(job.id, 'local-complete', expectedGeneration: 0);
      await writes.setProvider(
        job.id,
        provider: 'provider',
        model: 'model',
        expectedGeneration: 0,
      );
      await Future.wait<void>(<Future<void>>[
        writes.appendRejections(job.id, <String>[
          'first',
        ], expectedGeneration: 0),
        writes.appendRejections(job.id, <String>[
          'second',
          'first',
        ], expectedGeneration: 0),
      ]);
      final ProcessingJobRow current = await fixture.db
          .select(fixture.db.processing)
          .getSingle();
      expect(current.skipReason, 'local-complete');
      expect(current.provider, 'provider');
      expect(current.model, 'model');
      expect(
        jsonDecode(current.rejections!),
        unorderedEquals(<String>['first', 'second']),
      );
    },
  );
}

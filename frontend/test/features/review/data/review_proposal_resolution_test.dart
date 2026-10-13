import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/data/proposal_preview.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/records/data/record_queries.dart';
import 'package:tapture/features/records/domain/record_history_event.dart';
import 'package:tapture/features/records/domain/record_value.dart';
import 'package:tapture/features/review/data/review_repository_impl.dart';

import '../../../support/processing_fixture.dart';

void main() {
  Future<ProcessingFixture> analysed({bool numeric = false}) async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    await fixture.addField('serial', pattern: r'SN\d{6}');
    await fixture.addField('model');
    if (numeric) await fixture.addField('capacity', type: 'number', unit: 'L');
    final ProcessingJob job = await fixture.job();
    final worker = fixture.worker(
      ocr: CountingOcr(
        'Serial: SN458923\nModel: CR-10${numeric ? '\nCapacity: 13L' : ''}',
      ),
    );
    await worker.perform(JobStage.prepare, job);
    await worker.perform(JobStage.onDevice, job);
    await worker.perform(JobStage.validate, job);
    return fixture;
  }

  Future<Map<String, String>> proposals(ProcessingFixture fixture) async =>
      <String, String>{
        for (final PreviewedValue value in (await ProposalPreview(
          db: fixture.db,
        ).forRecord(fixture.record.id)).getOrThrow())
          value.fieldKey: value.value,
      };

  test(
    'accepted and rejected proposals are atomic and survive reopening',
    () async {
      final ProcessingFixture fixture = await analysed();
      final Map<String, String> pending = await proposals(fixture);
      expect(pending.keys, containsAll(<String>['serial', 'model']));
      final ReviewRepositoryImpl review = ReviewRepositoryImpl(
        db: fixture.db,
        clock: fixture.clock,
      );
      final List<RecordField> before = await fixture.db
          .select(fixture.db.recordFields)
          .get();
      expect(
        await review.resolveProposals(
          fixture.record.id,
          accepted: <String, String>{'serial': pending['serial']!},
          rejected: <String, String>{'model': pending['model']!},
        ),
        isA<Success<void>>(),
      );
      final List<RecordField> fields = await fixture.db
          .select(fixture.db.recordFields)
          .get();
      final RecordField serial = fields.singleWhere(
        (field) => field.fieldKey == 'serial',
      );
      final RecordField model = fields.singleWhere(
        (field) => field.fieldKey == 'model',
      );
      expect(serial.valueFinal, pending['serial']);
      expect(serial.verified, isTrue);
      expect(model.valueFinal, '');
      expect(model.verified, isFalse);
      expect(
        fields.map((field) => field.valueRaw),
        before.map((field) => field.valueRaw),
      );
      expect(await proposals(fixture), isEmpty);
      expect(
        await ReviewRepositoryImpl(
          db: fixture.db,
        ).verify(fixture.record.id, <String>['model']),
        isA<Success<void>>(),
      );
      expect(
        (await fixture.db.select(fixture.db.recordFields).get())
            .singleWhere((field) => field.fieldKey == 'model')
            .verified,
        isFalse,
      );
      final decisions = (await fixture.db.select(fixture.db.auditLog).get())
          .where((entry) => entry.entityType == 'processing');
      expect(
        decisions.map((entry) => entry.reason),
        containsAll(<String>['proposal-accepted:0', 'proposal-rejected:0']),
      );
      final List<RecordHistoryEvent> history = await RecordQueries(
        db: fixture.db,
      ).watchHistory(fixture.record.id).first;
      expect(
        history.any(
          (RecordHistoryEvent event) =>
              event.fieldKey == 'model' &&
              event.next == '' &&
              event.kind == RecordHistoryKind.valueChanged,
        ),
        isTrue,
      );
    },
  );

  test('a decision outside the current proposal set writes nothing', () async {
    final ProcessingFixture fixture = await analysed();
    final List<RecordField> before = await fixture.db
        .select(fixture.db.recordFields)
        .get();
    final int audits =
        (await fixture.db.select(fixture.db.auditLog).get()).length;
    final Result<void> result = await ReviewRepositoryImpl(db: fixture.db)
        .resolveProposals(
          fixture.record.id,
          accepted: const <String, String>{'serial': 'invented-value'},
          rejected: const <String, String>{'model': 'CR-10'},
        );
    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure, isA<ValidationFailure>());
    expect(await fixture.db.select(fixture.db.recordFields).get(), before);
    expect((await fixture.db.select(fixture.db.auditLog).get()).length, audits);
  });

  test(
    'rejecting a normalised numeric reading preserves evidence and stays empty',
    () async {
      final ProcessingFixture fixture = await analysed(numeric: true);
      final Map<String, String> pending = await proposals(fixture);
      expect(pending, contains('capacity'));
      final RecordField before =
          (await fixture.db.select(fixture.db.recordFields).get()).singleWhere(
            (field) => field.fieldKey == 'capacity',
          );
      expect(
        await ReviewRepositoryImpl(db: fixture.db).resolveProposals(
          fixture.record.id,
          rejected: <String, String>{'capacity': pending['capacity']!},
        ),
        isA<Success<void>>(),
      );
      final RecordField field =
          (await fixture.db.select(fixture.db.recordFields).get()).singleWhere(
            (field) => field.fieldKey == 'capacity',
          );
      expect(field.valueRaw, before.valueRaw);
      expect(field.valueRefined, before.valueRefined);
      expect(
        RecordValue(
          fieldKey: field.fieldKey,
          raw: field.valueRaw ?? '',
          refined: field.valueRefined,
          approved: field.valueFinal,
        ).display,
        isEmpty,
      );
      expect((await proposals(fixture)).keys, isNot(contains('capacity')));
    },
  );

  test(
    'rejecting an offered replacement preserves a prior human final value',
    () async {
      final ProcessingFixture fixture = await analysed();
      final Map<String, String> pending = await proposals(fixture);
      final String model = pending['model']!;
      await (fixture.db.update(
        fixture.db.recordFields,
      )..where(($RecordFieldsTable t) => t.fieldKey.equals('model'))).write(
        const RecordFieldsCompanion(
          valueFinal: Value<String?>('Operator choice'),
        ),
      );
      final Result<void> result = await ReviewRepositoryImpl(db: fixture.db)
          .resolveProposals(
            fixture.record.id,
            rejected: <String, String>{'model': model},
          );
      expect(result, isA<Success<void>>());
      expect(
        (await fixture.db.select(fixture.db.recordFields).get())
            .singleWhere((field) => field.fieldKey == 'model')
            .valueFinal,
        'Operator choice',
      );
    },
  );
}

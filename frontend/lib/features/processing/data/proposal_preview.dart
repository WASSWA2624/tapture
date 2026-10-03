import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/proposal_application.dart';
import 'ocr_cache.dart';
import 'processing_job_mapper.dart';
import 'proposal_collector.dart';
import 'record_bundle.dart';
import 'record_bundle_loader.dart';
import 'response_store.dart';

/// What processing proposes for a record from what it has already read,
/// worked out without writing anything (task 016 step 6).
///
/// Re-analysis runs the job again through the queue; proposal application
/// then skips every verified, hand-entered or already filled value. This
/// reads the same guarded proposals the validate stage collected, from the
/// record's latest job, so review can offer each one beside the current
/// value instead of applying it.
final class ProposalPreview {
  /// Creates the preview over [db].
  ProposalPreview({required AppDatabase db, Clock clock = const SystemClock()})
    : _db = db,
      _loader = RecordBundleLoader(db: db),
      _collector = ProposalCollector(
        cache: OcrCache(
          db: db,
          clock: clock,
          deviceId: '',
          ids: UuidV7Service(clock),
        ),
        responses: ResponseStore(
          db: db,
          clock: clock,
          deviceId: '',
          ids: UuidV7Service(clock),
        ),
      );

  final AppDatabase _db;
  final RecordBundleLoader _loader;
  final ProposalCollector _collector;

  /// Every non-empty guarded proposal for [recordId] from its latest job,
  /// one per field. Empty when the record has never been processed.
  Future<Result<List<PreviewedValue>>> forRecord(String recordId) async {
    try {
      final ProcessingJobRow? row =
          await (_db.select(_db.processing)
                ..where(
                  ($ProcessingTable table) => table.recordId.equals(recordId),
                )
                ..orderBy(<OrderClauseGenerator<$ProcessingTable>>[
                  ($ProcessingTable table) => OrderingTerm.desc(table.queuedAt),
                ])
                ..limit(1))
              .getSingleOrNull();
      if (row == null) {
        return const Success<List<PreviewedValue>>(<PreviewedValue>[]);
      }
      final RecordBundle bundle = await _loader.load(recordId);
      final ProposalSelection selection = await _collector.collect(
        ProcessingJobMapper.toJob(row),
        bundle,
      );
      return Success<List<PreviewedValue>>(<PreviewedValue>[
        for (final ProposedValue proposal in selection.proposals)
          if ((proposal.value ?? '').trim().isNotEmpty)
            (
              fieldKey: proposal.fieldKey,
              value: proposal.value!,
              confidence: proposal.confidence,
            ),
      ]);
    } on Failure catch (failure) {
      return FailureResult<List<PreviewedValue>>(failure);
    } on Object catch (error) {
      return FailureResult<List<PreviewedValue>>(storageFailureFrom(error));
    }
  }
}

/// One proposal: the field, the value processing would propose, and how sure
/// it was, 0 to 1.
typedef PreviewedValue = ({String fieldKey, String value, double confidence});

/// The preview over the database opened in `main`.
final Provider<ProposalPreview> proposalPreviewProvider =
    Provider<ProposalPreview>((Ref ref) {
      return ProposalPreview(db: ref.watch(appDatabaseProvider));
    });

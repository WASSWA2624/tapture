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
import 'processing_value_normalisation.dart';
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
  ProposalPreview({
    required AppDatabase db,
    Clock clock = const SystemClock(),
    ProposalCollector? collector,
    this._locale,
  }) : _db = db,
       _loader = RecordBundleLoader(db: db),
       _hasVerifiedCollector = collector != null,
       _collector =
           collector ??
           ProposalCollector(
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
  final String Function()? _locale;
  final bool _hasVerifiedCollector;

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
      final RecordBundle bundle = await _loader.load(
        recordId,
        fieldKeys: ProcessingJobMapper.toJob(row).fieldKeys,
      );
      if (!_hasVerifiedCollector && bundle.photos.isNotEmpty) {
        final AuditLogData? privacy =
            await (_db.select(_db.auditLog)
                  ..where(
                    ($AuditLogTable audit) =>
                        audit.entityType.equals('photos') &
                        audit.entityId.isIn(
                          bundle.photos.map((Photo photo) => photo.id),
                        ) &
                        audit.fieldKey.equals('privacy'),
                  )
                  ..limit(1))
                .getSingleOrNull();
        // Masked text needs the production file/selection boundary to be read.
        if (privacy != null) {
          return const Success<List<PreviewedValue>>(<PreviewedValue>[]);
        }
      }
      final ProposalSelection selection = await _collector.collect(
        ProcessingJobMapper.toJob(row),
        bundle,
      );
      final List<AuditLogData> decisions =
          await (_db.select(_db.auditLog)..where(
                ($AuditLogTable audit) =>
                    audit.entityType.equals('processing') &
                    audit.entityId.equals(row.id) &
                    audit.reason.isIn(<String>[
                      'proposal-accepted:${row.requestGeneration}',
                      'proposal-rejected:${row.requestGeneration}',
                    ]),
              ))
              .get();
      final Set<String> resolved = <String>{
        for (final AuditLogData decision in decisions)
          if (decision.fieldKey != null) decision.fieldKey!,
      };
      return Success<List<PreviewedValue>>(<PreviewedValue>[
        for (final ProposedValue proposal in selection.proposals)
          if (!resolved.contains(proposal.fieldKey) &&
              (proposal.value ?? '').trim().isNotEmpty)
            (
              fieldKey: proposal.fieldKey,
              value:
                  ProcessingValueNormalisation.read(
                    proposal.value!,
                    bundle.fields.firstWhere(
                      (TemplateField field) =>
                          field.fieldKey == proposal.fieldKey,
                    ),
                    locale: _locale?.call() ?? 'en',
                  ).normalised ??
                  proposal.value!,
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

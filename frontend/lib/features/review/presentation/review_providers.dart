import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/fields/field_value.dart' show ValueSource;
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/processing/processing.dart'
    show PreviewedValue, proposalPreviewProvider;
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/templates/templates.dart'
    show FieldDef, TemplateDef, TemplateVersioning, templateRepositoryProvider;

import '../domain/review_repository.dart';
import '../review.dart' show reviewRepositoryProvider;
import 'raw_refined_toggle.dart' show ValueSide;
import 'reanalyse_action.dart' show ReanalyseProposal;
import 'review_cursor.dart';
import 'review_position.dart';
import 'review_side_memory.dart';

export 'review_cursor.dart';
export 'review_position.dart';
export 'review_side_memory.dart';

/// What review reads beside record [recordId]'s values: conflicts,
/// verifiers and evidence. Read again whenever the record changes, so a
/// verify or a side choice shows at once.
final reviewFactsProvider = FutureProvider.autoDispose
    .family<ReviewFacts, String>((Ref ref, String recordId) async {
      ref.watch(recordEntryProvider(recordId));
      final Result<ReviewFacts> read = await ref
          .watch(reviewRepositoryProvider)
          .facts(recordId);
      return switch (read) {
        Success<ReviewFacts>(:final ReviewFacts value) => value,
        FailureResult<ReviewFacts>(:final failure) => throw failure,
      };
    }, retry: (int _, Object _) => null);

/// The template shape record [recordId] was captured with, which names its
/// fields; null when the template is not on this device. The current shape
/// stands in when the captured version cannot be rebuilt.
final reviewTemplateProvider = FutureProvider.autoDispose
    .family<TemplateDef?, String>((Ref ref, String recordId) async {
      final RecordEntry? entry = await ref.watch(
        recordEntryProvider(recordId).future,
      );
      if (entry == null) {
        return null;
      }
      final Result<TemplateDef?> read = await ref
          .watch(templateRepositoryProvider)
          .byId(entry.templateId);
      final TemplateDef? template = switch (read) {
        Success<TemplateDef?>(:final TemplateDef? value) => value,
        FailureResult<TemplateDef?>(:final failure) => throw failure,
      };
      if (template == null) {
        return null;
      }
      return TemplateVersioning.shapeFor(template, entry.templateVersion) ??
          template;
    }, retry: (int _, Object _) => null);

/// [projectId]'s records waiting for review, newest first: the queue the
/// batch review walks and approve-and-next moves along.
final reviewQueueProvider = StreamProvider.autoDispose
    .family<List<String>, String>((Ref ref, String projectId) {
      return ref
          .watch(recordRepositoryProvider)
          .watchPage(
            projectId,
            filter: RecordFilter.forStatus(RecordStatus.needsReview),
            sort: RecordSort.newestFirst,
            offset: 0,
            limit: AppConstants.lists.pageSize,
          )
          .map(
            (List<RecordSummary> rows) => <String>[
              for (final RecordSummary row in rows) row.id,
            ],
          );
    }, retry: (int _, Object _) => null);

/// The side a two-sided value starts on: the most recent choice, kept in
/// the project settings store so the next field starts there too.
final reviewSideProvider = NotifierProvider<ReviewSideMemory, ValueSide>(
  ReviewSideMemory.new,
);

/// What re-analysis now proposes for record [recordId] beside each current
/// value, one per field whose proposal differs from what the field shows.
/// A verified or hand-typed value is offered only, never applied.
final reviewProposalsProvider = FutureProvider.autoDispose
    .family<List<ReanalyseProposal>, String>((Ref ref, String recordId) async {
      final RecordEntry? entry = await ref.watch(
        recordEntryProvider(recordId).future,
      );
      if (entry == null) {
        return const <ReanalyseProposal>[];
      }
      final TemplateDef? template = await ref.watch(
        reviewTemplateProvider(recordId).future,
      );
      final Result<List<PreviewedValue>> read = await ref
          .watch(proposalPreviewProvider)
          .forRecord(recordId);
      final List<PreviewedValue> proposed = switch (read) {
        Success<List<PreviewedValue>>(:final List<PreviewedValue> value) =>
          value,
        FailureResult<List<PreviewedValue>>(:final failure) => throw failure,
      };
      final Map<String, String> labels = <String, String>{
        for (final FieldDef field in template?.fields ?? const <FieldDef>[])
          if (field.label.trim().isNotEmpty) field.fieldKey: field.label,
      };
      return <ReanalyseProposal>[
        for (final PreviewedValue value in proposed)
          if (_differs(entry.valueOf(value.fieldKey), value.value))
            (
              fieldKey: value.fieldKey,
              label: labels[value.fieldKey] ?? value.fieldKey,
              current: entry.valueOf(value.fieldKey)?.display ?? '',
              proposed: value.value,
              offeredOnly: _heldByPerson(entry.valueOf(value.fieldKey)),
            ),
      ];
    }, retry: (int _, Object _) => null);

bool _differs(RecordValue? current, String proposed) {
  return (current?.display ?? '').trim() != proposed.trim();
}

bool _heldByPerson(RecordValue? value) {
  if (value == null || !value.hasValue) {
    return false;
  }
  return value.verified || value.valueSource == ValueSource.manual;
}

/// Where the batch review of project [projectId] stands. Auto-dispose: only
/// the open batch review reads it (FE-STATE-09).
final reviewCursorProvider = NotifierProvider.autoDispose
    .family<ReviewCursor, ReviewPosition, String>(ReviewCursor.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/validation/validation_issue.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/quality/quality.dart' show RecordRules;
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/templates/templates.dart'
    show
        FieldDef,
        TemplateDef,
        TemplateRepository,
        TemplateVersioning,
        templateRepositoryProvider;

import '../domain/approval_outcome.dart';
import '../domain/approve_record.dart';
import '../domain/review_repository.dart';
import '../review.dart' show reviewRepositoryProvider;
import 'raw_refined_toggle.dart' show ValueSide, isTwoSided;
import 'review_providers.dart' show reviewSideProvider;

/// The one way a record reaches approved (task 016): the review screen,
/// the batch queue, the record page, a bulk selection and a meeting review
/// all approve through here, so validation, an unresolved duplicate and an
/// unresolved conflict block every one of them alike.
final reviewApproverProvider = Provider.autoDispose<ReviewApprover>((Ref ref) {
  return ReviewApprover(
    records: ref.watch(recordRepositoryProvider),
    templates: ref.watch(templateRepositoryProvider),
    review: ref.watch(reviewRepositoryProvider),
    side: ref.watch(reviewSideProvider),
  );
});

/// Runs `approveAndNext` over the stores.
final class ReviewApprover {
  /// Creates the approver over the stores, with [side] as the side a
  /// two-sided value without a chosen final value is approved on.
  const ReviewApprover({
    required this._records,
    required this._templates,
    required this._review,
    required this._side,
  });

  final RecordRepository _records;
  final TemplateRepository _templates;
  final ReviewRepository _review;
  final ValueSide _side;

  /// Approves [recordId] unless something blocks it, stamping [reason] on
  /// the status move, and names the next record of [queue] to review.
  ///
  /// A block is a [Success] carrying [Blocked]; a store that refuses is a
  /// [FailureResult]. Anything else thrown is left to the caller.
  Future<Result<ApprovalOutcome>> approve(
    String recordId, {
    List<String> queue = const <String>[],
    String? reason,
  }) async {
    try {
      return Success<ApprovalOutcome>(
        await approveAndNext(
          recordId,
          RecordFilter.forStatus(RecordStatus.needsReview),
          steps: _Steps(this, queue, reason ?? Copy.reviewApprovedReason),
        ),
      );
    } on Failure catch (refused) {
      return FailureResult<ApprovalOutcome>(refused);
    }
  }
}

/// The reads and the status move for one approval. The record and its
/// template are read once and shared by every check.
final class _Steps implements ApprovalSteps {
  _Steps(this._approver, this._queue, this._reason);

  final ReviewApprover _approver;
  final List<String> _queue;
  final String _reason;
  Future<({RecordEntry entry, TemplateDef? template})>? _loaded;

  Future<({RecordEntry entry, TemplateDef? template})> _load(String id) {
    return _loaded ??= _read(id);
  }

  Future<({RecordEntry entry, TemplateDef? template})> _read(String id) async {
    final RecordEntry? entry = switch (await _approver._records.byId(id)) {
      Success<RecordEntry?>(:final RecordEntry? value) => value,
      FailureResult<RecordEntry?>(:final Failure failure) => throw failure,
    };
    if (entry == null) {
      throw StorageFailure(
        localizedMessage: Copy.messages.reviewRecordGone,
        localizedRecovery: Copy.messages.reviewRecordGoneAction,
      );
    }
    final TemplateDef? template = switch (await _approver._templates.byId(
      entry.templateId,
    )) {
      Success<TemplateDef?>(:final TemplateDef? value) => value,
      FailureResult<TemplateDef?>(:final Failure failure) => throw failure,
    };
    return (
      entry: entry,
      template: template == null
          ? null
          : TemplateVersioning.shapeFor(template, entry.templateVersion) ??
                template,
    );
  }

  @override
  Future<List<ValidationIssue>> issues(String recordId) async {
    final (:RecordEntry entry, :TemplateDef? template) = await _load(recordId);
    if (template == null) {
      return const <ValidationIssue>[];
    }
    return RecordRules.validateRecord(
      template: template,
      values: <String, Object?>{
        for (final RecordValue value in entry.liveValues)
          value.fieldKey: _approvedText(value),
      },
      hasEvidence: entry.photos.isNotEmpty,
    );
  }

  @override
  Future<bool> unresolvedDuplicate(String recordId) async {
    final (:RecordEntry entry, template: _) = await _load(recordId);
    return entry.flags.contains(RecordFlag.hasDuplicate);
  }

  @override
  Future<Map<String, String>> conflictFields(String recordId) async {
    final (:RecordEntry entry, :TemplateDef? template) = await _load(recordId);
    if (!entry.flags.contains(RecordFlag.hasConflict)) {
      return const <String, String>{};
    }
    final ReviewFacts facts = switch (await _approver._review.facts(recordId)) {
      Success<ReviewFacts>(:final ReviewFacts value) => value,
      FailureResult<ReviewFacts>(:final Failure failure) => throw failure,
    };
    final Map<String, String> labels = <String, String>{
      for (final FieldDef field in template?.fields ?? const <FieldDef>[])
        if (field.label.trim().isNotEmpty) field.fieldKey: field.label,
    };
    return <String, String>{
      for (final String key in facts.conflicts) key: labels[key] ?? key,
    };
  }

  @override
  Future<String?> nextUnreviewed(RecordFilter filter, String recordId) async {
    final List<String> rest = <String>[
      for (final String id in _queue)
        if (id != recordId) id,
    ];
    final int at = _queue.indexOf(recordId);
    if (at < 0) {
      return rest.isEmpty ? null : rest.first;
    }
    return at + 1 < _queue.length ? _queue[at + 1] : null;
  }

  @override
  Future<void> markApproved(String recordId) async {
    final (:RecordEntry entry, template: _) = await _load(recordId);
    if (_approver._side == ValueSide.raw) {
      for (final RecordValue value in entry.liveValues) {
        if (isTwoSided(value) && (value.approved ?? '').isEmpty) {
          final Result<void> chosen = await _approver._review.chooseFinal(
            recordId,
            value.fieldKey,
            value.raw,
          );
          if (chosen case FailureResult<void>(:final Failure failure)) {
            throw failure;
          }
        }
      }
    }
    final Result<void> moved = await _approver._records.transition(
      recordId,
      RecordStatus.approved,
      reason: _reason,
    );
    if (moved case FailureResult<void>(:final Failure failure)) {
      throw failure;
    }
  }

  /// What [value] is approved as: its chosen final value, else the side
  /// the project starts two-sided values on.
  String _approvedText(RecordValue value) {
    if ((value.approved ?? '').isEmpty &&
        isTwoSided(value) &&
        _approver._side == ValueSide.raw) {
      return value.raw;
    }
    return value.display;
  }
}

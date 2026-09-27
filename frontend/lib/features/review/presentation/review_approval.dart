import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/validation/severity.dart';
import 'package:tapture/core/validation/validation_issue.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/quality/quality.dart' show RecordRules;
import 'package:tapture/features/records/records.dart';
import 'package:tapture/features/templates/templates.dart' show TemplateDef;

import '../domain/approval_outcome.dart';
import '../domain/approval_steps.dart';
import '../domain/approve_record.dart';

/// Approves one record in a review queue and reports the outcome (task 016).
///
/// The screen stays a reader. This path validates, blocks on an unresolved
/// duplicate or conflict, then moves a clean record to approved.
abstract final class ReviewApproval {
  /// Validates [recordId] and approves it when nothing blocks.
  ///
  /// [queue] is the filtered review order. The next id is the one after
  /// [recordId] in that list.
  static Future<void> approve(
    BuildContext context,
    WidgetRef ref, {
    required String recordId,
    required List<String> queue,
  }) async {
    try {
      final ApprovalOutcome outcome = await approveAndNext(
        recordId,
        RecordFilter.forStatus(RecordStatus.needsReview),
        steps: _Steps(ref, queue),
      );
      if (!context.mounted) {
        return;
      }
      switch (outcome) {
        case Approved():
          showAppSnack(
            context,
            Copy.recordsApproved(1),
            tone: SnackTone.success,
          );
        case Blocked(:final List<ValidationIssue> reasons):
          showAppSnack(
            context,
            reasons.isEmpty ? Copy.reviewBlockedAction : reasons.first.message,
            tone: SnackTone.error,
          );
      }
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnack(context, Failure.from(error).message, tone: SnackTone.error);
    }
  }
}

class _Steps implements ApprovalSteps {
  _Steps(this._ref, this._queue);

  final WidgetRef _ref;
  final List<String> _queue;
  RecordEntry? _entry;
  TemplateDef? _template;
  bool _read = false;

  Future<RecordEntry?> _record(String recordId) async {
    if (_read) {
      return _entry;
    }
    _read = true;
    final Result<RecordEntry?> loaded = await _ref
        .read(recordRepositoryProvider)
        .byId(recordId);
    switch (loaded) {
      case Success<RecordEntry?>(:final RecordEntry? value):
        _entry = value;
      case FailureResult<RecordEntry?>(:final Failure failure):
        throw failure;
    }
    final RecordEntry? entry = _entry;
    if (entry == null) {
      return null;
    }
    _template = await _ref.read(
      recordEditTemplateProvider(entry.templateId).future,
    );
    return entry;
  }

  @override
  Future<List<ValidationIssue>> issues(String recordId) async {
    final RecordEntry? entry = await _record(recordId);
    final TemplateDef? template = _template;
    if (entry == null || template == null) {
      return const <ValidationIssue>[
        ValidationIssue(null, Severity.error, Copy.reviewEmptyMessage),
      ];
    }
    final List<ValidationIssue> found = RecordRules.validateRecord(
      template: template,
      values: <String, Object?>{
        for (final RecordValue value in entry.values)
          value.fieldKey: value.display,
      },
      hasEvidence: entry.photos.isNotEmpty,
    );
    if (entry.flags.contains(RecordFlag.hasConflict) &&
        _conflictKeys(entry).isEmpty) {
      found.add(
        ValidationIssue(
          null,
          Severity.error,
          Copy.conflictBlocksApproval(
            entry.name.isEmpty ? entry.id : entry.name,
          ),
        ),
      );
    }
    return found;
  }

  @override
  Future<bool> unresolvedDuplicate(String recordId) async {
    final RecordEntry? entry = await _record(recordId);
    return entry?.flags.contains(RecordFlag.hasDuplicate) ?? false;
  }

  @override
  Future<List<String>> conflictFields(String recordId) async {
    final RecordEntry? entry = await _record(recordId);
    if (entry == null) {
      return const <String>[];
    }
    return _conflictKeys(entry);
  }

  @override
  Future<String?> nextUnreviewed(RecordFilter filter, String recordId) async {
    if (filter.statuses.isNotEmpty &&
        !filter.statuses.contains(RecordStatus.needsReview)) {
      return null;
    }
    final int at = _queue.indexOf(recordId);
    if (at < 0 || at + 1 >= _queue.length) {
      return null;
    }
    return _queue[at + 1];
  }

  @override
  Future<void> markApproved(String recordId) async {
    final Result<void> written = await _ref
        .read(recordRepositoryProvider)
        .transition(
          recordId,
          RecordStatus.approved,
          reason: Copy.reviewApprovedReason,
        );
    if (written case FailureResult<void>(:final Failure failure)) {
      throw failure;
    }
  }

  List<String> _conflictKeys(RecordEntry entry) {
    return <String>[
      for (final RecordValue value in entry.values)
        if (value.evidenceRemoved) value.fieldKey,
    ];
  }
}

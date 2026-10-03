import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/validation/validation_issue.dart';
import 'package:tapture/features/quality/quality.dart' show RecordRules;
import 'package:tapture/features/templates/templates.dart';

import '../domain/record_repository.dart';
import '../records.dart' show recordRepositoryProvider;
import 'record_field_input.dart';

/// Save state of the values of the record id it is created with.
/// Auto-dispose: the edit page and the one-value sheet are its only readers
/// (FE-STATE-09).
final recordEditControllerProvider = NotifierProvider.autoDispose
    .family<RecordEditController, RecordEditState, String>(
      RecordEditController.new,
    );

/// Writes the values a person changed on one record (task 014 step 5).
///
/// Every change is checked against its field's type first, through the same
/// registry the inline editor uses, so a value capture would refuse is
/// refused here too (FE-CONS-01). What passes is written in one repository
/// call: one transaction, one audit row per changed value, and an approved
/// record back to review.
final class RecordEditController extends Notifier<RecordEditState> {
  /// Creates the controller for [recordId].
  RecordEditController(this.recordId);

  /// The record being edited.
  final String recordId;

  @override
  RecordEditState build() => _idle;

  /// Checks [changes], then writes them. A change the field's type refuses,
  /// or one that empties a saved value, writes nothing: [state] lists why,
  /// field by field. A store failure is kept in [state] too; nothing typed
  /// is lost either way (FE-SIMP-09). No change is a success that writes
  /// nothing.
  Future<Result<void>> save(List<RecordFieldChange> changes) async {
    if (state.saving) {
      return const Success<void>(null);
    }
    if (changes.isEmpty) {
      state = _idle;
      return const Success<void>(null);
    }
    final List<LocalizedMessage> messages = _problemsIn(changes);
    final List<String> problems = messages
        .map((LocalizedMessage m) => m.fallback)
        .toList(growable: false);
    if (problems.isNotEmpty) {
      state = (
        saving: false,
        failure: null,
        problems: problems,
        localizedProblems: messages,
      );
      return FailureResult<void>(
        ValidationFailure(localizedMessage: messages.first),
      );
    }
    state = (
      saving: true,
      failure: null,
      problems: const <String>[],
      localizedProblems: const <LocalizedMessage>[],
    );
    final RecordRepository repository = ref.read(recordRepositoryProvider);
    Result<void> written;
    try {
      written = await repository.editValues(recordId, <RecordValueEdit>[
        for (final RecordFieldChange change in changes)
          (fieldKey: change.entry.fieldKey, value: change.text),
      ]);
    } on Object catch (error) {
      written = FailureResult<void>(Failure.from(error));
    }
    if (!ref.mounted) {
      return written;
    }
    state = switch (written) {
      Success<void>() => _idle,
      FailureResult<void>(:final Failure failure) => (
        saving: false,
        failure: failure,
        problems: const <String>[],
        localizedProblems: const <LocalizedMessage>[],
      ),
    };
    return written;
  }

  /// Forgets the refused-field lines once the person edits again, so the
  /// form never lists a field that may now be right. A store failure stays
  /// until the next Save, beside what was typed (FE-SIMP-09).
  void clearProblems() {
    if (state.saving || state.problems.isEmpty) {
      return;
    }
    state = (
      saving: false,
      failure: state.failure,
      problems: const <String>[],
      localizedProblems: const <LocalizedMessage>[],
    );
  }

  List<LocalizedMessage> _problemsIn(List<RecordFieldChange> changes) {
    final Map<String, Object?> siblings = <String, Object?>{
      for (final RecordFieldChange change in changes)
        change.entry.fieldKey: change.text,
    };
    final List<LocalizedMessage> problems = <LocalizedMessage>[];
    for (final RecordFieldChange change in changes) {
      final RecordEditEntry entry = change.entry;
      // Withdrawal is a durable operator correction. Required consent will
      // hold this record at the export gate rather than prevent withdrawal.
      if (entry.field.type == FieldType.consent && change.text.trim().isEmpty) {
        continue;
      }
      if (entry.initial.isNotEmpty && change.text.trim().isEmpty) {
        problems.add(
          Copy.messages
              .fieldError(entry.label, Copy.recordValueCannotEmpty)
              .withArgument('error', Copy.messages.recordValueCannotEmpty),
        );
        continue;
      }
      final List<ValidationIssue> issues = RecordRules.validateField(
        entry.field,
        change.text,
        siblings,
      );
      for (final ValidationIssue issue in issues) {
        if (issue.blocks) {
          problems.add(
            Copy.messages
                .fieldError(entry.label, issue.message)
                .withArgument('error', issue.explanation),
          );
        }
      }
    }
    return problems;
  }
}

/// One edited field and the text the person left in it.
typedef RecordFieldChange = ({RecordEditEntry entry, String text});

/// Save progress of one record's values: whether a save is running, the
/// store failure of the last one, and the fields it refused, each as a line
/// naming the field. Ephemeral (FE-STATE-02).
typedef RecordEditState = ({
  bool saving,
  Failure? failure,
  List<String> problems,
  List<LocalizedMessage> localizedProblems,
});

const RecordEditState _idle = (
  saving: false,
  failure: null,
  problems: <String>[],
  localizedProblems: <LocalizedMessage>[],
);

/// The template record values are edited against, by template id; null
/// when it is no longer on this device. Auto-dispose: read by the edit page
/// and the one-value sheet only (FE-STATE-09).
final recordEditTemplateProvider = FutureProvider.autoDispose
    .family<TemplateDef?, String>((Ref ref, String templateId) async {
      final Result<TemplateDef?> loaded = await ref
          .watch(templateRepositoryProvider)
          .byId(templateId);
      return switch (loaded) {
        Success<TemplateDef?>(:final TemplateDef? value) => value,
        FailureResult<TemplateDef?>(:final Failure failure) => throw failure,
      };
    }, retry: (int _, Object _) => null);

/// Resolves the saved shape, so later template edits cannot silently retype a record.
final recordCapturedTemplateProvider = Provider.autoDispose
    .family<AsyncValue<TemplateDef?>, ({String id, int version})>(
      (Ref ref, ({String id, int version}) captured) => ref
          .watch(recordEditTemplateProvider(captured.id))
          .whenData((TemplateDef? template) {
            if (template == null) return null;
            final TemplateDef? shape = TemplateVersioning.shapeFor(
              template,
              captured.version,
            );
            if (shape == null) {
              throw StorageFailure(
                localizedMessage: Copy
                    .messages
                    .failureTheCapturedTemplateVersionIsUnavailable,
                localizedRecovery: Copy
                    .messages
                    .failureRestoreTheOriginalProjectPackageBeforeEditing,
              );
            }
            return shape;
          }),
    );

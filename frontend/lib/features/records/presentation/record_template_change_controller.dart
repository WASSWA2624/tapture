import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/templates.dart'
    show TemplateDef, templateRepositoryProvider;

import '../domain/record_repository.dart';
import '../domain/template_change_plan.dart';
import '../records.dart' show recordRepositoryProvider;

/// Every template of project [projectId]: the one a record is on, and the
/// ones it can move to. Auto-dispose: the template change sheet is its only
/// reader (FE-STATE-09).
final recordTemplateChangeChoicesProvider = StreamProvider.autoDispose
    .family<List<TemplateDef>, String>((Ref ref, String projectId) {
      return ref.watch(templateRepositoryProvider).watchByProject(projectId);
    }, retry: (int _, Object _) => null);

/// What moving a record to a template would do to its values, read before
/// anything changes (task 014 step 5). A plan that cannot be made is an
/// error the sheet shows in place of the preview.
final recordTemplateChangePlanProvider = FutureProvider.autoDispose
    .family<TemplateChangePlan, RecordTemplateChangeTarget>((
      Ref ref,
      RecordTemplateChangeTarget target,
    ) async {
      final Result<TemplateChangePlan> planned = await ref
          .watch(recordRepositoryProvider)
          .planTemplateChange(target.recordId, target.templateId);
      return switch (planned) {
        Success<TemplateChangePlan>(:final TemplateChangePlan value) => value,
        FailureResult<TemplateChangePlan>(:final Failure failure) =>
          throw failure,
      };
    }, retry: (int _, Object _) => null);

/// The template change of the record id it is created with: the chosen
/// template, and whether applying it is running or failed. Auto-dispose:
/// the sheet is its only reader (FE-STATE-09).
final recordTemplateChangeControllerProvider = NotifierProvider.autoDispose
    .family<RecordTemplateChangeController, RecordTemplateChangeState, String>(
      RecordTemplateChangeController.new,
    );

/// Moves one record to another template (task 014 step 5): the operator
/// chooses the template, reads what maps, what is retired and what starts
/// empty, then applies. Values are never deleted; the repository keeps the
/// ones the new template has no field for as retired, and sends an approved
/// record back to review in the same transaction.
final class RecordTemplateChangeController
    extends Notifier<RecordTemplateChangeState> {
  /// Creates the controller for [recordId].
  RecordTemplateChangeController(this.recordId);

  /// The record being moved.
  final String recordId;

  @override
  RecordTemplateChangeState build() {
    return (targetId: null, applying: false, failure: null);
  }

  /// Chooses [templateId] as the template to move to, clearing the failure
  /// of an earlier attempt. Ignored while a move is being applied.
  void choose(String templateId) {
    if (state.applying || state.targetId == templateId) {
      return;
    }
    state = (targetId: templateId, applying: false, failure: null);
  }

  /// Moves the record to the chosen template. A failure is kept in the
  /// state, beside the chosen template, so the sheet can say why and the
  /// operator can try again.
  Future<Result<void>> apply() async {
    final String? targetId = state.targetId;
    if (targetId == null) {
      return FailureResult<void>(_nothingChosen);
    }
    if (state.applying) {
      return FailureResult<void>(_alreadyApplying);
    }
    state = (targetId: targetId, applying: true, failure: null);
    final RecordRepository records = ref.read(recordRepositoryProvider);
    Result<void> written;
    try {
      written = await records.changeTemplate(recordId, targetId);
    } on Object catch (error) {
      written = FailureResult<void>(Failure.from(error));
    }
    if (!ref.mounted) {
      return written;
    }
    state = (
      targetId: targetId,
      applying: false,
      failure: switch (written) {
        Success<void>() => null,
        FailureResult<void>(:final Failure failure) => failure,
      },
    );
    return written;
  }
}

/// A record and the template it may move to: what a plan is read for.
typedef RecordTemplateChangeTarget = ({String recordId, String templateId});

/// A template change in progress: the template chosen, if any, whether it is
/// being applied, and why the last attempt failed. Ephemeral (FE-STATE-02).
typedef RecordTemplateChangeState = ({
  String? targetId,
  bool applying,
  Failure? failure,
});

final ValidationFailure _nothingChosen = ValidationFailure(
  message: Copy.recordTemplateChangeHint,
  recoveryAction: Copy.recordTemplateChangeChooseAction,
);

final ValidationFailure _alreadyApplying = ValidationFailure(
  message: Copy.recordTemplateChangeApplying,
  recoveryAction: Copy.recordTemplateChangeApplyingAction,
);

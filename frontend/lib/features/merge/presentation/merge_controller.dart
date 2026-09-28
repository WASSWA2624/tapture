import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/bundle/inspected_bundle.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/quality/quality.dart'
    hide ConflictChoice, FieldConflict;

import '../domain/compatibility_report.dart';
import '../domain/conflict_choice.dart';
import '../domain/merge_plan.dart';
import '../domain/merge_planner.dart';
import '../domain/package_import_repository.dart';
import '../domain/template_compatibility.dart';
import '../merge.dart' show packageImportRepositoryProvider;
import 'merge_view.dart';
import 'package_import_controller.dart';

/// The merge of the open package into one project (task 076, W20 to W22).
/// Null when no package is open. Planning and the duplicate scan run off
/// the UI thread (FE-PERF-02); nothing is written before [apply].
final mergeControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MergeController, MergeView?, String>(MergeController.new);

/// Plans the merge, holds the person's choices, and applies them.
final class MergeController extends AsyncNotifier<MergeView?> {
  /// Creates the controller for the project [projectId].
  MergeController(this.projectId);

  /// The project the package merges into.
  final String projectId;

  @override
  Future<MergeView?> build() async {
    final InspectedBundle? bundle = ref.watch(
      packageImportControllerProvider.select(
        (PackageImportView view) => view.bundle,
      ),
    );
    final PackageImportRepository? repository = ref.watch(
      packageImportRepositoryProvider,
    );
    if (bundle == null || repository == null) {
      return null;
    }
    final MergeGround ground = _valueOf(
      await repository.groundFor(projectId: projectId, incoming: bundle.tables),
    );
    final _Planned planned = _valueOf(
      await runIsolate<_Planning, _Planned>(
        _planInIsolate,
        _planning(bundle, ground, skipped: const <String>{}, scan: true),
      ),
    );
    return MergeView(
      bundle: bundle,
      report: planned.report,
      plan: planned.plan,
      local: ground.local,
      duplicates: planned.duplicates,
    );
  }

  MergeGround? _ground;

  _Planning _planning(
    InspectedBundle bundle,
    MergeGround ground, {
    required Set<String> skipped,
    required bool scan,
  }) {
    _ground = ground;
    return (
      incoming: bundle.tables,
      local: ground.local,
      elsewhere: ground.elsewhere,
      decided: ground.decided,
      target: projectId,
      source: bundle.manifest.projectId,
      skipped: skipped,
      scan: scan,
    );
  }

  /// Records [choice] for the conflict [conflictId].
  void choose(String conflictId, ConflictChoice choice) {
    final MergeView? view = state.value;
    if (view == null) {
      return;
    }
    state = AsyncData<MergeView?>(
      view.copyWith(
        choices: <String, ConflictChoice>{...view.choices, conflictId: choice},
      ),
    );
  }

  /// Records [choice] for every conflict still unsettled.
  void chooseAll(ConflictChoice choice) {
    final MergeView? view = state.value;
    if (view == null) {
      return;
    }
    state = AsyncData<MergeView?>(
      view.copyWith(
        choices: <String, ConflictChoice>{
          ...view.choices,
          for (final conflict in view.unsettled) conflict.id: choice,
        },
      ),
    );
  }

  /// Turns the duplicate check on or off. Off forgets every pair and every
  /// record left out because of one (FE-SIMP-08).
  Future<void> setCheckDuplicates(bool check) async {
    final MergeView? view = state.value;
    if (view == null || view.checkDuplicates == check) {
      return;
    }
    state = AsyncData<MergeView?>(
      view.copyWith(
        checkDuplicates: check,
        duplicates: const <PossibleDuplicate>[],
      ),
    );
    await _replan(skipped: const <String>{}, scan: check);
  }

  /// Leaves the incoming record [incomingId] out of the merge, or brings it
  /// back when [skip] is false.
  Future<void> setSkipped(String incomingId, {required bool skip}) async {
    final MergeView? view = state.value;
    if (view == null) {
      return;
    }
    await _replan(
      skipped: skip
          ? <String>{...view.skipped, incomingId}
          : <String>{
              for (final String id in view.skipped)
                if (id != incomingId) id,
            },
      scan: false,
    );
  }

  Future<void> _replan({
    required Set<String> skipped,
    required bool scan,
  }) async {
    final MergeView? view = state.value;
    final MergeGround? ground = _ground;
    if (view == null || ground == null) {
      return;
    }
    final Result<_Planned> planned = await runIsolate<_Planning, _Planned>(
      _planInIsolate,
      _planning(view.bundle, ground, skipped: skipped, scan: scan),
    );
    final MergeView? now = state.value;
    if (now == null || !ref.mounted) {
      return;
    }
    switch (planned) {
      case FailureResult<_Planned>(:final Failure failure):
        state = AsyncError<MergeView?>(failure, StackTrace.current);
      case Success<_Planned>(:final _Planned value):
        final Set<String> open = <String>{
          for (final conflict in value.plan.conflicts) conflict.id,
        };
        state = AsyncData<MergeView?>(
          now.copyWith(
            report: value.report,
            plan: value.plan,
            skipped: skipped,
            duplicates: scan ? value.duplicates : now.duplicates,
            choices: <String, ConflictChoice>{
              for (final MapEntry<String, ConflictChoice> choice
                  in now.choices.entries)
                if (open.contains(choice.key)) choice.key: choice.value,
            },
          ),
        );
    }
  }

  /// Writes the merge as planned and chosen. [chooser] names who decided.
  Future<Result<MergeOutcome>> apply({required String chooser}) async {
    final MergeView? view = state.value;
    final PackageImportRepository? repository = ref.read(
      packageImportRepositoryProvider,
    );
    if (view == null || repository == null) {
      return const FailureResult<MergeOutcome>(CancelledFailure());
    }
    state = AsyncData<MergeView?>(view.copyWith(applying: true, progress: 0));
    final PackageImportController flow = ref.read(
      packageImportControllerProvider.notifier,
    )..writing(writing: true);
    final Result<MergeOutcome> merged = await repository.merge(
      bundle: view.bundle,
      projectId: projectId,
      plan: view.plan,
      choices: view.choices,
      duplicates: view.checkDuplicates
          ? view.duplicates
          : const <PossibleDuplicate>[],
      skipped: view.skipped,
      chooser: chooser,
      onProgress: (double progress) {
        if (ref.mounted && state.value != null) {
          state = AsyncData<MergeView?>(
            state.value!.copyWith(progress: progress),
          );
        }
      },
    );
    if (merged case FailureResult<MergeOutcome>()) {
      flow.writing(writing: false);
      if (ref.mounted && state.value != null) {
        state = AsyncData<MergeView?>(
          state.value!.copyWith(applying: false, progress: 0),
        );
      }
    } else {
      await flow.applied();
    }
    return merged;
  }
}

typedef _Planning = ({
  Map<String, List<Map<String, Object?>>> incoming,
  Map<String, List<Map<String, Object?>>> local,
  Map<String, Set<String>> elsewhere,
  Set<String> decided,
  String target,
  String source,
  Set<String> skipped,
  bool scan,
});

typedef _Planned = ({
  CompatibilityReport report,
  MergePlan plan,
  List<PossibleDuplicate> duplicates,
});

/// Checks, plans and scans in one pass, on the isolate runner.
_Planned _planInIsolate(_Planning job) {
  final CompatibilityReport report = TemplateCompatibility.check(
    incoming: job.incoming,
    local: job.local,
    sameProject: job.target == job.source,
  );
  final MergePlan plan = MergePlanner.plan(
    incoming: job.incoming,
    local: job.local,
    templateMapping: report.mapping,
    targetProjectId: job.target,
    incomingProjectId: job.source,
    elsewhere: job.elsewhere,
    skipRecords: job.skipped,
    decided: job.decided,
  );
  return (
    report: report,
    plan: plan,
    duplicates: job.scan
        ? DuplicateSignals.find(
            incoming: job.incoming,
            local: job.local,
            templateMapping: report.mapping,
            candidates: plan.insertedRecords,
          )
        : const <PossibleDuplicate>[],
  );
}

T _valueOf<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw failure,
  };
}

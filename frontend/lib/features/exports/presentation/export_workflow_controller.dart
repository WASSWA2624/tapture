import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/merge/merge.dart' show BundleScopeKind;
import 'package:tapture/features/records/records.dart';

import '../exports.dart';
import 'export_workflow.dart';

/// Auto-disposed session: leaving the screen cancels an active writer.
final exportWorkflowControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ExportWorkflowController, ExportWorkflow, String>(
      ExportWorkflowController.new,
      retry: (int _, Object _) => null,
    );

final class ExportWorkflowController extends AsyncNotifier<ExportWorkflow> {
  ExportWorkflowController(this.projectId);

  final String projectId;
  CancellationToken? _cancel;

  DeliverableRepository get _store =>
      ref.read(deliverableRepositoryProvider) ?? (throw _unavailable);

  @override
  Future<ExportWorkflow> build() async {
    ref.onDispose(() => _cancel?.cancel());
    final ExportRequest request = _value(await _store.options(projectId));
    return ExportWorkflow(
      request: request,
      withoutPhotos: request.extras.photoMode == 'none',
    );
  }

  /// Persist choices before the interface confirms them.
  Future<void> change(ExportRequest request) async {
    final ExportWorkflow? current = state.value;
    if (current == null || current.running) return;
    final Result<void> saved = await _store.remember(request);
    if (!ref.mounted) return;
    switch (saved) {
      case FailureResult<void>(:final Failure failure):
        state = AsyncError<ExportWorkflow>(failure, StackTrace.current);
      case Success<void>():
        state = AsyncData<ExportWorkflow>(current.copyWith(request: request));
    }
  }

  void toggleAdvanced() {
    final ExportWorkflow? current = state.value;
    if (current == null || current.running) return;
    state = AsyncData<ExportWorkflow>(
      current.copyWith(advanced: !current.advanced),
    );
  }

  /// Changes package inclusion without storing its optional password.
  Future<void> bundleScope(BundleScopeKind kind) async {
    final ExportScopeKind selected = switch (kind) {
      BundleScopeKind.full ||
      BundleScopeKind.withoutPhotos => ExportScopeKind.all,
      BundleScopeKind.approved => ExportScopeKind.approved,
      BundleScopeKind.context => ExportScopeKind.context,
      BundleScopeKind.dateRange => ExportScopeKind.dateRange,
    };
    await scope(selected);
    final ExportWorkflow? selectedWorkflow = state.value;
    if (selectedWorkflow != null) {
      await change(
        selectedWorkflow.request.copyWith(
          extras: (
            dictionary: selectedWorkflow.request.extras.dictionary,
            photoIndex: selectedWorkflow.request.extras.photoIndex,
            photoMode: kind == BundleScopeKind.withoutPhotos ? 'none' : 'path',
            pdfPhotos: selectedWorkflow.request.extras.pdfPhotos,
            delimiter: selectedWorkflow.request.extras.delimiter,
          ),
        ),
      );
    }
    final ExportWorkflow? current = state.value;
    if (current != null && ref.mounted) {
      state = AsyncData<ExportWorkflow>(
        current.copyWith(withoutPhotos: kind == BundleScopeKind.withoutPhotos),
      );
    }
  }

  /// Holds a password only for this open session; it never enters remembered options.
  void password(String value) {
    final ExportWorkflow? current = state.value;
    if (current != null && !current.running) {
      state = AsyncData<ExportWorkflow>(current.copyWith(password: value));
    }
  }

  void cancel() => _cancel?.cancel();

  Future<void> scope(ExportScopeKind kind) async {
    final ExportWorkflow? current = state.value;
    if (current == null) return;
    try {
      Map<String, Object?>? filter;
      if (kind == ExportScopeKind.filter) {
        filter = ref
            .read(recordsListControllerProvider(projectId))
            .filter
            .toJson();
      } else if (kind == ExportScopeKind.context) {
        final ContextState context = await ref.read(
          projectContextProvider(projectId).future,
        );
        filter = RecordFilter(
          context: <String, Set<String>>{
            for (final MapEntry<String, String> level in context.values.entries)
              if (level.value.isNotEmpty) level.key: <String>{level.value},
          },
        ).toJson();
      }
      if (!ref.mounted) return;
      await change(
        current.request.copyWith(
          scope: (
            kind: kind,
            context: null,
            from: current.request.scope.from,
            to: current.request.scope.to,
            filter: filter,
          ),
        ),
      );
    } on Object catch (error, stack) {
      if (ref.mounted) {
        state = AsyncError<ExportWorkflow>(Failure.from(error), stack);
      }
    }
  }

  /// The gate is provided by the shared dialog surface. No writer runs
  /// until the user has resolved every issue the request selects.
  Future<void> run({
    required Future<ExportGateChoice?> Function(PreparedDeliverable) decide,
    ExportRequest? replay,
  }) async {
    final ExportWorkflow? current = state.value;
    if (current == null || current.running) return;
    final ExportRequest request = replay ?? current.request;
    final CancellationToken token = CancellationToken();
    _cancel = token;
    state = AsyncData<ExportWorkflow>(
      current.copyWith(running: true, progress: <String, double>{'records': 0}),
    );
    try {
      final DeliverableEntry written;
      if (request.isProjectPackage) {
        final ExportRepository package =
            ref.read(exportRepositoryProvider) ?? (throw _unavailable);
        final ExportedPackage result = _value(
          await package.exportProject(
            projectId,
            cancel: token,
            scope: request.scope,
            withoutPhotos: replay == null
                ? current.withoutPhotos
                : request.extras.photoMode == 'none',
            password: current.password?.isEmpty == false
                ? current.password
                : null,
            onStageProgress: (DeliverableProgress step) =>
                _progress(step.stage, step.fraction),
          ),
        );
        final List<DeliverableEntry> history = await _store
            .watchHistory(projectId: projectId)
            .first;
        written = history.singleWhere(
          (DeliverableEntry entry) => entry.id == result.id,
        );
      } else {
        final PreparedDeliverable prepared = replay == null
            ? _value(await _store.prepare(request, cancel: token))
            : (
                request: request,
                validation: (
                  incomplete: const <String>[],
                  unapproved: const <String>[],
                  blocked: const <String>[],
                ),
              );
        ExportRequest resolved = prepared.request;
        if (!ExportValidation.isClean(prepared.validation)) {
          final ExportGateChoice? choice = await decide(prepared);
          if (choice == null || !ref.mounted) return;
          final ExportGate gate = ExportValidation.apply(
            request: resolved,
            report: prepared.validation,
            choice: choice,
          );
          if (!gate.proceed) return;
          resolved = gate.request;
        }
        if (token.isCancelled) throw const CancelledFailure();
        written = _value(
          await _store.write(
            resolved,
            cancel: token,
            onProgress: (DeliverableProgress step) =>
                _progress(step.stage, step.fraction),
          ),
        );
      }
      if (ref.mounted) {
        state = AsyncData<ExportWorkflow>(
          current.copyWith(saved: written, progress: const <String, double>{}),
        );
      }
    } on Object catch (error, stack) {
      if (ref.mounted) {
        state = error is CancelledFailure
            ? AsyncData<ExportWorkflow>(current)
            : AsyncError<ExportWorkflow>(Failure.from(error), stack);
      }
    } finally {
      _cancel = null;
      if (ref.mounted && state.value?.running == true) {
        state = AsyncData<ExportWorkflow>(current);
      }
    }
  }

  void _progress(String stage, double fraction) {
    if (!ref.mounted) return;
    final ExportWorkflow? current = state.value;
    if (current == null) return;
    state = AsyncData<ExportWorkflow>(
      current.copyWith(
        progress: <String, double>{...current.progress, stage: fraction},
      ),
    );
  }
}

final StorageFailure _unavailable = StorageFailure(
  localizedMessage: Copy.messages.failureProjectFilesAreUnavailableOnThisDevice,
  localizedRecovery: Copy.messages.failureOpenAProjectStoredOnThisDevice,
);

T _value<T>(Result<T> result) => switch (result) {
  Success<T>(:final T value) => value,
  FailureResult<T>(:final Failure failure) => throw failure,
};

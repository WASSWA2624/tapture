import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';

import '../domain/package_import_repository.dart';
import '../domain/package_presence.dart';
import '../merge.dart' show packageImportRepositoryProvider;
import 'package_import_phase.dart';

/// The package a person is bringing in, from pick to import or merge (task
/// 076, W19). Kept alive across the merge screens, which read [bundle];
/// [finish] closes it and deletes the picker's copy.
final packageImportControllerProvider =
    NotifierProvider<PackageImportController, PackageImportView>(
      PackageImportController.new,
    );

/// Picks, checks and imports project packages. Nothing is written before
/// the person confirms (FE-STATE-07).
class PackageImportController extends Notifier<PackageImportView> {
  PickedDocument? _picked;
  CancellationToken? _checking;

  /// The open package, kept apart from [state] so disposal can close it.
  InspectedBundle? _open;

  @override
  PackageImportView build() {
    ref.onDispose(() => unawaited(_release(_open)));
    return _idle;
  }

  /// Asks for a package file, closing any package still open.
  Future<Result<PickedDocument>> pick() async {
    await finish();
    return ref
        .read(documentPickerProvider)
        .pick(
          extensions: const <String>[BundleFormat.extension],
          mimeType: BundleFormat.mimeType,
          maxBytes: kIsWeb
              ? AppConstants.imports.bundleMaxBytes
              : AppConstants.bundles.nativeMaxBytes,
        );
  }

  /// Opens and checks [picked]. A [CancelledFailure] when [cancel] was
  /// called first; the package is then closed as soon as it opens.
  Future<Result<InspectedBundle>> check(PickedDocument picked) async {
    _picked = picked;
    final CancellationToken token = CancellationToken();
    _checking = token;
    state = (phase: PackageImportPhase.checking, bundle: null, progress: 0);
    final Future<Result<InspectedBundle>> inspecting = BundleReader.inspect(
      picked,
    );
    final Result<InspectedBundle>? first =
        await Future.any<Result<InspectedBundle>?>(
          <Future<Result<InspectedBundle>?>>[
            inspecting,
            token.whenCancelled.then((_) => null),
          ],
        );
    if (first == null || token.isCancelled) {
      unawaited(
        inspecting.then((Result<InspectedBundle> late) async {
          if (late case Success<InspectedBundle>(
            :final InspectedBundle value,
          )) {
            await value.close();
          }
        }),
      );
      await finish();
      return const FailureResult<InspectedBundle>(CancelledFailure());
    }
    _checking = null;
    switch (first) {
      case FailureResult<InspectedBundle>():
        await finish();
      case Success<InspectedBundle>(:final InspectedBundle value):
        _open = value;
        state = (phase: PackageImportPhase.ready, bundle: value, progress: 0);
    }
    return first;
  }

  /// Stops [check]; the flow returns at once.
  void cancel() {
    _checking?.cancel();
  }

  /// Whether the open package's project is on this device, and live.
  Future<Result<PackagePresence>> presence() async {
    final InspectedBundle? bundle = state.bundle;
    final PackageImportRepository? repository = ref.read(
      packageImportRepositoryProvider,
    );
    if (bundle == null || repository == null) {
      return const FailureResult<PackagePresence>(CancelledFailure());
    }
    return repository.presenceOf(bundle.manifest.projectId);
  }

  /// Imports the open package as the project it carries.
  Future<Result<ImportedProject>> importAsNew() async {
    final InspectedBundle? bundle = state.bundle;
    final PackageImportRepository? repository = ref.read(
      packageImportRepositoryProvider,
    );
    if (bundle == null || repository == null) {
      return const FailureResult<ImportedProject>(CancelledFailure());
    }
    state = (phase: PackageImportPhase.writing, bundle: bundle, progress: 0);
    final Result<ImportedProject> imported = await repository.importAsNew(
      bundle,
      onProgress: _progress,
    );
    if (imported case Success<ImportedProject>()) {
      await finish();
    } else {
      state = (phase: PackageImportPhase.ready, bundle: bundle, progress: 0);
    }
    return imported;
  }

  /// Marks a merge as writing, with [progress] from 0 to 1, or back to
  /// ready when [writing] is false.
  void writing({required bool writing, double progress = 0}) {
    final InspectedBundle? bundle = state.bundle;
    if (bundle == null) {
      return;
    }
    state = (
      phase: writing ? PackageImportPhase.writing : PackageImportPhase.ready,
      bundle: bundle,
      progress: progress,
    );
  }

  /// Closes the package and deletes the picker's copy of it.
  Future<void> finish() async {
    final InspectedBundle? bundle = _open;
    _open = null;
    _checking = null;
    state = _idle;
    await _release(bundle);
  }

  void _progress(double progress) {
    writing(writing: true, progress: progress);
  }

  Future<void> _release(InspectedBundle? bundle) async {
    await bundle?.close();
    final PickedDocument? picked = _picked;
    _picked = null;
    if (picked case PickedFile(isCopy: true, :final file)) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } on Object {
        // The cache is cleared by the platform in time.
      }
    }
  }
}

/// The flow's phase, the open package, and the write's progress (0–1).
typedef PackageImportView = ({
  PackageImportPhase phase,
  InspectedBundle? bundle,
  double progress,
});

const PackageImportView _idle = (
  phase: PackageImportPhase.idle,
  bundle: null,
  progress: 0,
);

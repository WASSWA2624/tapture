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
  /// Transport receipt callback, invoked only after a durable import or merge.
  Future<void> Function()? onApplied;
  PickedDocument? _picked;
  CancellationToken? _checking;
  Future<Result<InspectedBundle>>? _inspection;
  bool _disposed = false;

  /// The open package, kept apart from [state] so disposal can close it.
  InspectedBundle? _open;

  @override
  PackageImportView build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      unawaited(finish());
    });
    return _idle;
  }

  /// Asks for a package file, closing any package still open.
  Future<Result<PickedDocument>> pick() async {
    await finish();
    if (_disposed || !ref.mounted) {
      return const FailureResult<PickedDocument>(CancelledFailure());
    }
    state = (phase: PackageImportPhase.checking, bundle: null, progress: 0);
    final Result<PickedDocument> picked = await ref
        .read(documentPickerProvider)
        .pick(
          extensions: const <String>[BundleFormat.extension],
          mimeType: BundleFormat.mimeType,
          maxBytes: kIsWeb
              ? AppConstants.imports.bundleMaxBytes
              : AppConstants.bundles.nativeMaxBytes,
        );
    if (_disposed || !ref.mounted) {
      if (picked case Success<PickedDocument>(:final value)) {
        await discardPickedCopy(value);
      }
      return const FailureResult<PickedDocument>(CancelledFailure());
    }
    if (picked case Success<PickedDocument>(:final value)) {
      _picked = value;
    } else {
      await finish();
    }
    return picked;
  }

  /// Opens and checks [picked]. A [CancelledFailure] when [cancel] was
  /// called first; the package is then closed as soon as it opens.
  Future<Result<InspectedBundle>> check(
    PickedDocument picked, {
    String? password,
  }) async {
    _picked = picked;
    final CancellationToken token = CancellationToken();
    _checking = token;
    state = (phase: PackageImportPhase.checking, bundle: null, progress: 0);
    final Future<Result<InspectedBundle>> inspecting = BundleReader.inspect(
      picked,
      password: password,
      cancel: token,
    );
    _inspection = inspecting;
    final Result<InspectedBundle>? first = await token
        .race<Result<InspectedBundle>?>(inspecting, onCancel: () => null);
    if (first == null ||
        token.isCancelled ||
        _disposed ||
        !ref.mounted ||
        !identical(_checking, token)) {
      if (identical(_checking, token)) await finish();
      return const FailureResult<InspectedBundle>(CancelledFailure());
    }
    _inspection = null;
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

  /// Owns the picked copy while inspecting its password header, before prompting.
  Future<Result<bool>> needsPassword(PickedDocument picked) {
    _picked = picked;
    state = (phase: PackageImportPhase.checking, bundle: null, progress: 0);
    return BundleReader.needsPassword(picked);
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
      await applied();
      await finish();
    } else if (!_disposed && ref.mounted) {
      state = (phase: PackageImportPhase.ready, bundle: bundle, progress: 0);
    }
    return imported;
  }

  /// Marks a merge as writing, with [progress] from 0 to 1, or back to
  /// ready when [writing] is false.
  void writing({required bool writing, double progress = 0}) {
    if (_disposed || !ref.mounted) return;
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
    onApplied = null;
    _checking?.cancel();
    final InspectedBundle? bundle = _open;
    final PickedDocument? picked = _picked;
    final Future<Result<InspectedBundle>>? inspecting = _inspection;
    _open = null;
    _picked = null;
    _inspection = null;
    _checking = null;
    if (!_disposed && ref.mounted) state = _idle;
    if (inspecting != null) {
      // Inspection owns file handles until it returns. Cancellation returns
      // immediately; its late result releases the copy after closing them.
      unawaited(_releaseInspection(inspecting, picked));
    }
    await bundle?.close();
    if (inspecting == null) await discardPickedCopy(picked);
  }

  /// Confirms committed writes to the transport; preview and cancellation do not.
  Future<void> applied() async {
    final callback = onApplied;
    if (callback == null) return;
    await callback();
    onApplied = null;
  }

  void _progress(double progress) {
    writing(writing: true, progress: progress);
  }

  Future<void> _releaseInspection(
    Future<Result<InspectedBundle>> inspecting,
    PickedDocument? picked,
  ) async {
    try {
      if (await inspecting case Success<InspectedBundle>(:final value)) {
        await value.close();
      }
    } finally {
      await discardPickedCopy(picked);
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

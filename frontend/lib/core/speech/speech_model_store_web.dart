import 'dart:ui_web' as ui_web;

import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/bundled_assets.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'speech_engine.dart';
import 'speech_engine_web.dart';
import 'speech_failures.dart';
import 'speech_model_entry.dart';
import 'speech_model_source.dart';
import 'speech_model_status.dart';
import 'speech_model_store.dart';
import 'speech_worker_codec.dart';

/// The store in a browser: models are this build's assets, served from the
/// page's own origin and cached by the speech worker, which also verifies
/// them. [privateRoot] and [assets] describe files, which a browser has
/// none of; [webEngine] runs the verification.
SpeechModelStore openSpeechModelStore({
  required StorageRoot privateRoot,
  required BundledAssets assets,
  required List<SpeechModelEntry> catalogue,
  SpeechEngine? webEngine,
}) => _WebSpeechModelStore(catalogue, webEngine);

final class _WebSpeechModelStore implements SpeechModelStore {
  _WebSpeechModelStore(this._catalogue, this._engine);

  final List<SpeechModelEntry> _catalogue;
  final SpeechEngine? _engine;
  final Set<String> _damaged = <String>{};
  Set<String>? _bundled;

  /// Import is not offered in a browser: the only importable model may not
  /// run on the web.
  @override
  bool get canImport => false;

  /// The asset keys this build carries, read once from its manifest. A
  /// development build without models carries none of them.
  Future<Set<String>> _bundledKeys() async {
    final Set<String>? known = _bundled;
    if (known != null) {
      return known;
    }
    try {
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
        rootBundle,
      );
      return _bundled = manifest.listAssets().toSet();
    } on Object {
      return const <String>{};
    }
  }

  /// Whether the browser may load [entry] from this build.
  static bool _servable(SpeechModelEntry entry, Set<String> bundled) {
    final String? asset = entry.asset;
    return entry.webAllowed && asset != null && bundled.contains(asset);
  }

  @override
  Future<Result<List<SpeechModelStatus>>> inventory() async {
    final Set<String> bundled = await _bundledKeys();
    return Success<List<SpeechModelStatus>>(<SpeechModelStatus>[
      for (final SpeechModelEntry entry in _catalogue)
        SpeechModelStatus(
          entry: entry,
          present: _servable(entry, bundled),
          damaged: _damaged.contains(entry.id),
        ),
    ]);
  }

  /// The same-origin URL of [entry]'s asset. Nothing is fetched or hashed
  /// here: the worker fetches, caches and verifies at load.
  @override
  Future<Result<SpeechModelSource>> locate(
    SpeechModelEntry entry, {
    CancellationToken? cancel,
  }) async {
    final String? asset = entry.asset;
    if (asset == null || !_servable(entry, await _bundledKeys())) {
      return FailureResult<SpeechModelSource>(speechModelMissing());
    }
    return SpeechWorkerCodec.modelUrl(
      ui_web.assetManager.getAssetUrl(asset),
      base: Uri.base,
    ).map((Uri url) => SpeechModelSource(entry: entry, url: url));
  }

  @override
  Future<Result<SpeechModelSource>> reextract(SpeechModelEntry entry) =>
      locate(entry);

  /// Hashes the worker's cached copy of the model. With nothing cached
  /// there is nothing on this device to check: `speechModelMissing`, and
  /// the next load fetches and verifies the asset.
  @override
  Future<Result<void>> verify(
    SpeechModelSource source, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) async {
    final SpeechEngine? engine = _engine;
    if (engine == null) {
      return FailureResult<void>(speechUnavailable());
    }
    if (cancel?.isCancelled ?? false) {
      return FailureResult<void>(speechCancelled());
    }
    final Future<Result<({bool present, bool ok})>> work =
        verifyCachedSpeechModel(engine, source.entry);
    final Result<({bool present, bool ok})> checked = cancel == null
        ? await work
        : await cancel.race(
            work,
            onCancel: () =>
                FailureResult<({bool present, bool ok})>(speechCancelled()),
          );
    switch (checked) {
      case FailureResult<({bool present, bool ok})>(:final Failure failure):
        return FailureResult<void>(failure);
      case Success<({bool present, bool ok})>(value: (present: false, ok: _)):
        return FailureResult<void>(speechModelMissing());
      case Success<({bool present, bool ok})>(
        value: (present: true, ok: false),
      ):
        _damaged.add(source.entry.id);
        return FailureResult<void>(speechModelDamaged());
      case Success<({bool present, bool ok})>():
        _damaged.remove(source.entry.id);
        onProgress?.call(1);
        return const Success<void>(null);
    }
  }

  @override
  Future<Result<SpeechModelEntry>> import(
    PickedDocument picked, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) async {
    await discardPickedCopy(picked);
    return FailureResult<SpeechModelEntry>(speechImportUnknown());
  }

  /// Nothing is imported in a browser, so nothing can be removed.
  @override
  Future<Result<void>> remove(SpeechModelEntry entry) async =>
      const FailureResult<void>(ValidationFailure());

  @override
  void markDamaged(String modelId) {
    _damaged.add(modelId);
  }
}

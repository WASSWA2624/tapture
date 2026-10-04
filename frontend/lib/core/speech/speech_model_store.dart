import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/bundled_assets.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'speech_engine.dart';
import 'speech_failures.dart';
import 'speech_model_catalogue.dart';
import 'speech_model_entry.dart';
import 'speech_model_source.dart';
import 'speech_model_status.dart';
import 'speech_model_store_stub.dart'
    if (dart.library.io) 'speech_model_store_io.dart'
    as platform;

/// Where this device keeps each catalogue speech model, and the one place
/// that imports, verifies and removes them (spec §30.4.2).
///
/// Models are derived application files under [StorageRoot.private], never
/// evidence (spec §8.1 rule 8). Bundled models are read in place, or on
/// Android from a copy extracted once by SHA-256 prefix; imported models sit
/// in `speech/imported/`. Nothing here loads a model or uses the network.
abstract interface class SpeechModelStore {
  /// The store of this platform. Models are kept under [privateRoot] and
  /// bundled ones found through [assets]; [webEngine] serves a browser,
  /// which reads models by URL. [catalogue] is the test seam for the
  /// models the store knows.
  factory SpeechModelStore.platform({
    required StorageRoot privateRoot,
    required BundledAssets assets,
    SpeechEngine? webEngine,
    @visibleForTesting
    List<SpeechModelEntry> catalogue = SpeechModelCatalogue.all,
  }) => platform.openSpeechModelStore(
    privateRoot: privateRoot,
    assets: assets,
    webEngine: webEngine,
    catalogue: catalogue,
  );

  /// A store with nothing installed and no import: the provider default.
  const factory SpeechModelStore.empty() = _EmptySpeechModelStore;

  /// A stand-in holding [statuses] by model id; any other catalogue model
  /// is absent. An import fails with [importFailure] when one is given, and
  /// otherwise accepts a file the size of an import-only model.
  factory SpeechModelStore.fake(
    Map<String, SpeechModelStatus> statuses, {
    Failure? importFailure,
  }) = _FakeSpeechModelStore;

  /// Whether this platform can import a model the operator picks.
  bool get canImport;

  /// Every catalogue model's presence on this device, without hashing.
  Future<Result<List<SpeechModelStatus>>> inventory();

  /// A loadable source for [entry]. Android extracts a bundled model once;
  /// nothing is hashed, because the engine verifies at load. An absent model
  /// is `speechModelMissing`.
  Future<Result<SpeechModelSource>> locate(
    SpeechModelEntry entry, {
    CancellationToken? cancel,
  });

  /// Discards an extracted Android copy of [entry] and extracts it again;
  /// on every other platform, and for an imported model, the same as
  /// [locate].
  Future<Result<SpeechModelSource>> reextract(SpeechModelEntry entry);

  /// The full check of [source]: size, header and SHA-256 off the UI
  /// isolate. A failed check marks the model damaged; a passing one clears
  /// that mark.
  Future<Result<void>> verify(
    SpeechModelSource source, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  });

  /// Imports [picked] when it is exactly an import-only catalogue model by
  /// bytes and SHA-256, copying it atomically, and discards the picked copy
  /// whatever the outcome. Anything else is `speechImportUnknown`; a cancel
  /// leaves no partial file.
  Future<Result<SpeechModelEntry>> import(
    PickedDocument picked, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  });

  /// Removes the imported copy of [entry]. A bundled model cannot be
  /// removed and gives a `ValidationFailure`.
  Future<Result<void>> remove(SpeechModelEntry entry);

  /// Records that the model [modelId] failed to load for this session, so
  /// [inventory] reports it damaged.
  void markDamaged(String modelId);
}

/// The process-wide [SpeechModelStore]. Defaults to [SpeechModelStore.empty];
/// the app overrides it with [SpeechModelStore.platform].
final Provider<SpeechModelStore> speechModelStoreProvider =
    Provider<SpeechModelStore>((_) => const SpeechModelStore.empty());

final class _EmptySpeechModelStore implements SpeechModelStore {
  const _EmptySpeechModelStore();

  @override
  bool get canImport => false;

  @override
  Future<Result<List<SpeechModelStatus>>> inventory() async =>
      Success<List<SpeechModelStatus>>(<SpeechModelStatus>[
        for (final SpeechModelEntry entry in SpeechModelCatalogue.all)
          SpeechModelStatus(entry: entry, present: false),
      ]);

  @override
  Future<Result<SpeechModelSource>> locate(
    SpeechModelEntry entry, {
    CancellationToken? cancel,
  }) async => FailureResult<SpeechModelSource>(speechModelMissing());

  @override
  Future<Result<SpeechModelSource>> reextract(SpeechModelEntry entry) =>
      locate(entry);

  @override
  Future<Result<void>> verify(
    SpeechModelSource source, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) async => FailureResult<void>(speechModelMissing());

  @override
  Future<Result<SpeechModelEntry>> import(
    PickedDocument picked, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) async => FailureResult<SpeechModelEntry>(speechUnavailable());

  @override
  Future<Result<void>> remove(SpeechModelEntry entry) async =>
      FailureResult<void>(speechModelMissing());

  @override
  void markDamaged(String modelId) {}
}

final class _FakeSpeechModelStore implements SpeechModelStore {
  _FakeSpeechModelStore(
    Map<String, SpeechModelStatus> statuses, {
    this.importFailure,
  }) : _statuses = Map<String, SpeechModelStatus>.of(statuses);

  final Map<String, SpeechModelStatus> _statuses;
  final Failure? importFailure;

  @override
  bool get canImport => true;

  SpeechModelStatus _statusOf(SpeechModelEntry entry) =>
      _statuses[entry.id] ?? SpeechModelStatus(entry: entry, present: false);

  @override
  Future<Result<List<SpeechModelStatus>>> inventory() async =>
      Success<List<SpeechModelStatus>>(<SpeechModelStatus>[
        for (final SpeechModelEntry entry in SpeechModelCatalogue.all)
          _statusOf(entry),
      ]);

  @override
  Future<Result<SpeechModelSource>> locate(
    SpeechModelEntry entry, {
    CancellationToken? cancel,
  }) async {
    final SpeechModelStatus status = _statusOf(entry);
    if (!status.present) {
      return FailureResult<SpeechModelSource>(speechModelMissing());
    }
    return Success<SpeechModelSource>(
      SpeechModelSource(entry: entry, path: 'fake/${entry.fileName}'),
    );
  }

  @override
  Future<Result<SpeechModelSource>> reextract(SpeechModelEntry entry) =>
      locate(entry);

  @override
  Future<Result<void>> verify(
    SpeechModelSource source, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) async {
    final SpeechModelStatus status = _statusOf(source.entry);
    if (!status.present) {
      return FailureResult<void>(speechModelMissing());
    }
    if (status.damaged) {
      return FailureResult<void>(speechModelDamaged());
    }
    onProgress?.call(1);
    return const Success<void>(null);
  }

  @override
  Future<Result<SpeechModelEntry>> import(
    PickedDocument picked, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) async {
    final Failure? failure = importFailure;
    if (failure != null) {
      return FailureResult<SpeechModelEntry>(failure);
    }
    for (final SpeechModelEntry entry in SpeechModelCatalogue.all) {
      if (entry.asset == null && entry.bytes == picked.byteLength) {
        _statuses[entry.id] = SpeechModelStatus(
          entry: entry,
          present: true,
          imported: true,
        );
        onProgress?.call(1);
        return Success<SpeechModelEntry>(entry);
      }
    }
    return FailureResult<SpeechModelEntry>(speechImportUnknown());
  }

  @override
  Future<Result<void>> remove(SpeechModelEntry entry) async {
    if (!_statusOf(entry).imported) {
      return const FailureResult<void>(ValidationFailure());
    }
    _statuses.remove(entry.id);
    return const Success<void>(null);
  }

  @override
  void markDamaged(String modelId) {
    final SpeechModelEntry? entry = SpeechModelCatalogue.byId(modelId);
    if (entry == null) {
      return;
    }
    final SpeechModelStatus status = _statusOf(entry);
    _statuses[modelId] = SpeechModelStatus(
      entry: entry,
      present: status.present,
      imported: status.imported,
      damaged: true,
    );
  }
}

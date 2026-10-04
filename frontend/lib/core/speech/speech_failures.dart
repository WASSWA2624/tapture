import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/blob_store.dart' show storeFailure;

// The speech failure builders, one per row of spec §30.4.4. Only existing
// Failure variants are used. Engines build them on a worker as well as on
// the main isolate: their semantic messages are sendable.

/// The engine library is missing, speaks another ABI, or never started; or
/// the platform has no engine, or a browser could not fetch the worker.
ProviderFailure speechUnavailable() => ProviderFailure(
  kind: ProviderFailureKind.unavailable,
  localizedMessage: Copy.messages.speechUnavailable,
);

/// The processor, memory or browser cannot run the engine.
ProviderFailure speechDeviceUnsupported() => ProviderFailure(
  kind: ProviderFailureKind.unavailable,
  localizedMessage: Copy.messages.speechDeviceUnsupported,
);

/// The model file is absent or cannot be opened.
ProviderFailure speechModelMissing() => ProviderFailure(
  kind: ProviderFailureKind.unavailable,
  localizedMessage: Copy.messages.speechModelMissing,
  localizedRecovery: Copy.messages.speechModelMissingRecovery,
);

/// The model failed its size, header, SHA-256 or shape check.
CorruptionFailure speechModelDamaged() => CorruptionFailure(
  localizedMessage: Copy.messages.speechModelDamaged,
  localizedRecovery: Copy.messages.speechModelDamagedRecovery,
);

/// The model could not be loaded for lack of memory.
ProviderFailure speechLowMemory() => ProviderFailure(
  kind: ProviderFailureKind.unavailable,
  localizedMessage: Copy.messages.speechLowMemory,
  localizedRecovery: Copy.messages.speechLowMemoryRecovery,
);

/// Extracting or caching a model failed on this device's storage: no space
/// (the recovery says to free some), an input-output error, or browser
/// storage refusing the write.
Failure speechStorageFailed() => storeFailure();

/// A request was aborted, cancelled or superseded. Shown to nobody.
CancelledFailure speechCancelled() => const CancelledFailure();

/// The engine failed on one window. The pipeline retries once, then records
/// the window as a gap.
ProviderFailure speechTranscriptionFailed() =>
    ProviderFailure(localizedMessage: Copy.messages.speechTranscriptionFailed);

/// A request the contract refuses: an empty, oversized or partial-frame
/// window, or a language of `''` or `'auto'`. A caller's defect, logged as
/// an error by the engine.
ValidationFailure speechInvalidRequest() => const ValidationFailure();

/// The voice language has no whisper model.
ValidationFailure speechLanguageUnsupported() => ValidationFailure(
  localizedMessage: Copy.messages.speechLanguageUnsupported,
);

/// A worker ended unexpectedly, or the engine was disposed.
ProviderFailure speechEngineStopped() =>
    ProviderFailure(localizedMessage: Copy.messages.speechEngineStopped);

/// An imported file is not a model the catalogue knows.
ValidationFailure speechImportUnknown() => ValidationFailure(
  localizedMessage: Copy.messages.speechImportUnknown,
  localizedRecovery: Copy.messages.speechImportUnknownRecovery,
);

/// The platform recogniser would send speech off the device.
NetworkFailure speechOfflineOnly() =>
    NetworkFailure(localizedMessage: Copy.messages.dictationOfflineOnly);

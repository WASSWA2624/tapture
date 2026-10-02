import 'dart:async';

/// Secret checkpoint callbacks and source identity of one worker transfer.
final class CloudUploadContext {
  /// Creates the context after hashing the complete source on the worker.
  const CloudUploadContext({
    required this.fingerprint,
    required this.readSession,
    required this.writeSession,
    this.refreshNativeAccess,
  });

  /// SHA-256 and byte length of the source being uploaded.
  final String fingerprint;

  /// Reads the saved provider session from copied secure storage state.
  final Future<String?> Function() readSession;

  /// Persists and acknowledges a provider checkpoint before further bytes.
  final Future<void> Function(String? json) writeSession;

  /// Requests SDK token renewal on the parent isolate after a provider401.
  final Future<String> Function(String invalidToken)? refreshNativeAccess;

  /// Current transfer; absent for small destination checks.
  static CloudUploadContext? get current =>
      Zone.current[_key] as CloudUploadContext?;

  /// Native file slices are already off the UI isolate during a transfer.
  static bool get isWorker => Zone.current[_workerKey] == true;

  /// Marks the worker before source hashing starts.
  static Future<T> runWorker<T>(Future<T> Function() operation) =>
      runZoned(operation, zoneValues: <Object, Object>{_workerKey: true});

  /// Runs a transfer within the context.
  Future<T> run<T>(Future<T> Function() operation) =>
      runZoned(operation, zoneValues: <Object, Object>{_key: this});

  static final Object _key = Object();
  static final Object _workerKey = Object();
}

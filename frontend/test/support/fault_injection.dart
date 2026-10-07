import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// Dependencies a failure-path test can refuse.
enum Dependency {
  /// Camera permission or hardware.
  camera,

  /// Microphone permission or hardware.
  microphone,

  /// Disk is full.
  storage,

  /// The analysis provider cannot be reached.
  provider,

  /// A provider key was refused.
  key,

  /// A provider body could not be read.
  response,

  /// A bundle failed its checks.
  bundle,

  /// The database is locked.
  database,

  /// A capture process ends before publication.
  process,
}

/// Fails a named dependency until [clear].
final class FaultInjector {
  final Map<Dependency, Failure> _faults = <Dependency, Failure>{};

  /// Every use of [dependency] fails with [failure] until restored.
  void fail(Dependency dependency, Failure failure) {
    _faults[dependency] = failure;
  }

  /// The failure installed for [dependency], if a test asked for one.
  Failure? check(Dependency dependency) => _faults[dependency];

  /// The operation boundary. Refused operations never run their side effects.
  Future<Result<T>> run<T>(
    Dependency dependency,
    Future<Result<T>> Function() operation,
  ) {
    final Failure? failure = check(dependency);
    return failure == null
        ? operation()
        : Future<Result<T>>.value(FailureResult<T>(failure));
  }

  /// Restores one dependency, leaving concurrent failures in place.
  void restore(Dependency dependency) => _faults.remove(dependency);

  /// Installs a scoped refusal and restores the previous fault even on a throw.
  Future<T> during<T>(
    Dependency dependency,
    Failure failure,
    Future<T> Function() body,
  ) async {
    final Failure? previous = _faults[dependency];
    fail(dependency, failure);
    try {
      return await body();
    } finally {
      if (previous == null) {
        restore(dependency);
      } else {
        fail(dependency, previous);
      }
    }
  }

  /// Restores every dependency.
  void clear() {
    _faults.clear();
  }
}

/// The executable failure suite must register every injectable boundary.
/// Adding an enum value without an evidence-preservation/retry case fails.
Set<Dependency> missingFaultCases(Iterable<Dependency> registered) =>
    Dependency.values.toSet().difference(registered.toSet());

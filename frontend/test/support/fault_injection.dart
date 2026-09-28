import 'package:tapture/core/errors/failure.dart';

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
}

/// Fails a named dependency until [clear].
final class FaultInjector {
  final Map<Dependency, Failure> _faults = <Dependency, Failure>{};

  /// The next use of [dependency] fails with [failure].
  void fail(Dependency dependency, Failure failure) {
    _faults[dependency] = failure;
  }

  /// The failure installed for [dependency], if a test asked for one.
  Failure? check(Dependency dependency) => _faults[dependency];

  /// Restores every dependency.
  void clear() {
    _faults.clear();
  }
}

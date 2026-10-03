import 'package:tapture/core/errors/failure.dart';

/// What the scanner screen shows:the held code, why the scanner could not
/// start, whether it runs, the torch, whether the last frame could not be
/// read, and, in count mode, every code counted so far.
final class BarcodeScanState {
  /// Creates a state. Defaults describe a scanner that has not started.
  const BarcodeScanState({
    this.code,
    this.failure,
    this.started = false,
    this.torchOn = false,
    this.unreadable = false,
    this.counting = false,
    this.counted = const <String>[],
  });

  /// The decoded value waiting for confirm or rescan.
  final String? code;

  /// Why the scanner could not start.
  final Failure? failure;

  /// Whether the scanner is running.
  final bool started;

  /// Whether the torch is on.
  final bool torchOn;

  /// Whether the last frame could not be read.
  final bool unreadable;

  /// Whether every code is counted instead of one being held.
  final bool counting;

  /// The codes counted so far, oldest first.
  final List<String> counted;

  /// A copy with the given fields replaced. The `clear…` flags drop a value.
  BarcodeScanState copyWith({
    String? code,
    bool clearCode = false,
    Failure? failure,
    bool clearFailure = false,
    bool? started,
    bool? torchOn,
    bool? unreadable,
    bool? counting,
    List<String>? counted,
  }) {
    return BarcodeScanState(
      code: clearCode ? null : code ?? this.code,
      failure: clearFailure ? null : failure ?? this.failure,
      started: started ?? this.started,
      torchOn: torchOn ?? this.torchOn,
      unreadable: unreadable ?? this.unreadable,
      counting: counting ?? this.counting,
      counted: counted ?? this.counted,
    );
  }
}

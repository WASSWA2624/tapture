import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'microphone_lease.dart';
import 'microphone_owner.dart';

/// The one owner of the microphone, app-wide.
///
/// Evidence capture (a live transcription or the file recorder) takes the
/// microphone from field dictation, and nothing takes it from evidence
/// capture: a dictation claim, or a second evidence claim, is refused while
/// evidence is recording.
abstract interface class MicrophoneArbiter {
  /// A pure-Dart arbiter; it opens no plugin.
  factory MicrophoneArbiter() = _MicrophoneArbiter;

  /// Who holds the microphone now, or null when it is free.
  MicrophoneOwner? get holder;

  /// Every change of [holder], so a dictation microphone can hide while
  /// evidence capture holds it.
  Stream<MicrophoneOwner?> get changes;

  /// Grants the microphone to [owner].
  ///
  /// When dictation holds it and [owner] records evidence, dictation's
  /// [onPreempted] runs and it has `AppConstants.dictation.settle` to hand
  /// the microphone back before its lease is revoked. Any other busy
  /// microphone is a [ValidationFailure].
  Future<Result<MicrophoneLease>> claim(
    MicrophoneOwner owner, {
    Future<void> Function()? onPreempted,
  });
}

/// The process-wide arbiter, kept alive deliberately: there is one
/// microphone, so there is one owner record for the whole process.
final Provider<MicrophoneArbiter> microphoneArbiterProvider =
    Provider<MicrophoneArbiter>((Ref _) => MicrophoneArbiter());

/// The current lease and how to ask its holder to give it back.
typedef _Hold = ({
  MicrophoneLease lease,
  Future<void> Function()? onPreempted,
  Completer<void> released,
});

final class _MicrophoneArbiter implements MicrophoneArbiter {
  _MicrophoneArbiter();

  final StreamController<MicrophoneOwner?> _changes =
      StreamController<MicrophoneOwner?>.broadcast();
  _Hold? _hold;
  Future<void> _queue = Future<void>.value();

  @override
  MicrophoneOwner? get holder => _hold?.lease.owner;

  @override
  Stream<MicrophoneOwner?> get changes => _changes.stream;

  @override
  Future<Result<MicrophoneLease>> claim(
    MicrophoneOwner owner, {
    Future<void> Function()? onPreempted,
  }) {
    // Claims are decided one at a time, so two evidence claims racing for
    // a free microphone cannot both win.
    final Future<Result<MicrophoneLease>> decided = _queue.then(
      (_) => _decide(owner, onPreempted),
    );
    _queue = decided.then<void>((_) {});
    return decided;
  }

  Future<Result<MicrophoneLease>> _decide(
    MicrophoneOwner owner,
    Future<void> Function()? onPreempted,
  ) async {
    final _Hold? current = _hold;
    if (current != null) {
      if (current.lease.owner.isEvidence || !owner.isEvidence) {
        return FailureResult<MicrophoneLease>(
          ValidationFailure(localizedMessage: Copy.messages.microphoneBusy),
        );
      }
      await _preempt(current);
    }
    final MicrophoneLease lease = MicrophoneLease(owner, onRelease: _released);
    _hold = (
      lease: lease,
      onPreempted: onPreempted,
      released: Completer<void>(),
    );
    _changes.add(owner);
    return Success<MicrophoneLease>(lease);
  }

  /// Asks dictation to stop, waits for it to hand the microphone back, and
  /// revokes the lease if it has not within the settle time.
  Future<void> _preempt(_Hold current) async {
    try {
      await current.onPreempted?.call();
    } on Object {
      // A holder that fails to stop is revoked below all the same.
    }
    if (!current.released.isCompleted) {
      await current.released.future.timeout(
        AppConstants.dictation.settle,
        onTimeout: current.lease.release,
      );
    }
  }

  void _released(MicrophoneLease lease) {
    final _Hold? current = _hold;
    if (current == null || !identical(current.lease, lease)) {
      return;
    }
    _hold = null;
    current.released.complete();
    _changes.add(null);
  }
}

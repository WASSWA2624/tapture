import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/volume_stats.dart';

/// Free space for one visit to capture, read through the core
/// [StorageGuard] (task 012 step 21, task 005 step 5).
///
/// Polls when capture opens and again whenever the app resumes, never per
/// shutter. While the volume cannot be read (a browser, a failed probe) the
/// level stays null and capture proceeds unguarded: nothing blocks capture
/// but a known full device.
final captureHeadroomProvider =
    NotifierProvider.autoDispose<CaptureHeadroom, CaptureHeadroomView>(
      CaptureHeadroom.new,
    );

/// Drives the guard's session policy for the capture screen.
final class CaptureHeadroom extends Notifier<CaptureHeadroomView> {
  StreamSubscription<HeadroomState>? _changes;

  @override
  CaptureHeadroomView build() {
    final StorageGuard guard = ref.watch(storageGuardProvider);
    ref.onDispose(() => unawaited(_changes?.cancel()));
    unawaited(_begin(guard));
    return (level: null, freeBytes: null, warnLow: false);
  }

  /// Hides the low-space warning for the rest of this visit.
  void dismissLow() {
    state = (level: state.level, freeBytes: state.freeBytes, warnLow: false);
  }

  /// Whether a new capture may start. Only a known critical level refuses,
  /// with a failure that names export and cache cleanup. Null while the
  /// level is unknown, which admits.
  Future<Result<HeadroomState>?> admit() async {
    if (state.level == null) {
      return null;
    }
    return ref.read(storageGuardProvider).admitCapture();
  }

  /// Runs [save] even if the device has just turned full, so a photo
  /// already taken is written rather than lost.
  Future<Result<T>> complete<T>(Future<Result<T>> Function() save) {
    return ref.read(storageGuardProvider).completeSave(save);
  }

  Future<void> _begin(StorageGuard guard) async {
    final Result<HeadroomState> begun = await guard.beginSession();
    if (!ref.mounted || begun is! Success<HeadroomState>) {
      return;
    }
    await _show(guard, begun.value);
    if (!ref.mounted) {
      return;
    }
    // Later polls, on resume, move the level; the first is replayed.
    await _changes?.cancel();
    _changes = guard.watch().listen(
      (HeadroomState level) => unawaited(_show(guard, level)),
    );
  }

  Future<void> _show(StorageGuard guard, HeadroomState level) async {
    int? free;
    if (level != HeadroomState.ample) {
      final Result<VolumeStats> stats = await guard.volume();
      if (stats case Success<VolumeStats>(:final VolumeStats value)) {
        free = value.freeBytes;
      }
    }
    if (!ref.mounted) {
      return;
    }
    // Warned once per visit (FE-SIMP-08); a dismissed warning stays hidden.
    final bool warn =
        level == HeadroomState.low && (guard.takeLowWarning() || state.warnLow);
    state = (level: level, freeBytes: free, warnLow: warn);
  }
}

/// What capture shows about free space.
typedef CaptureHeadroomView = ({
  HeadroomState? level,
  int? freeBytes,
  bool warnLow,
});

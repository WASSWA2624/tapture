import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/storage_root.dart';

/// Watched free-space headroom on the storage root's volume.
///
/// Capture reads this instead of a plugin. Tests pass [StorageGuard.fake] so
/// they never touch the disk (FE-STR-11, FE-TEST-03).
abstract interface class StorageGuard {
  /// Resolves free space through [storageRoot].
  ///
  /// When [lifecycle] emits [AppLifecycleState.resumed], this polls once.
  /// [freeBytes] is the test seam for a fake volume size.
  factory StorageGuard({
    required StorageRoot storageRoot,
    Stream<AppLifecycleState>? lifecycle,
    Future<int> Function(Directory root)? freeBytes,
  }) {
    return _StorageGuard(
      storageRoot: storageRoot,
      lifecycle: lifecycle,
      freeBytes: freeBytes ?? _platformFreeBytes,
    );
  }

  /// A stand-in driven by [freeBytes], so tests never spawn `df` or PowerShell.
  factory StorageGuard.fake({
    required StorageRoot storageRoot,
    required int Function() freeBytes,
    Stream<AppLifecycleState>? lifecycle,
  }) {
    return _StorageGuard(
      storageRoot: storageRoot,
      lifecycle: lifecycle,
      freeBytes: (Directory _) async => freeBytes(),
    );
  }

  /// Current headroom. Replays the last value to a new listener.
  Stream<HeadroomState> watch();

  /// Reads free space now and classifies it. Call on resume and at session
  /// start — not per shutter.
  Future<Result<HeadroomState>> check();

  /// Polls once for a new capture session and clears the low warning.
  Future<Result<HeadroomState>> beginSession();

  /// True once per session while headroom is [HeadroomState.low]. Capture
  /// still proceeds; the warning is dismissible (FE-SIMP-08).
  bool takeLowWarning();

  /// Starts a new capture from the last poll. [HeadroomState.critical] is a
  /// [StorageFailure] that names export and cache cleanup.
  Future<Result<HeadroomState>> admitCapture();

  /// Runs [save] even if the volume is now critical, so a photo already
  /// taken is never discarded.
  Future<Result<T>> completeSave<T>(Future<Result<T>> Function() save);

  /// Cancels the lifecycle subscription and closes [watch].
  Future<void> dispose();
}

/// Free space relative to [AppConstants.storage].
enum HeadroomState {
  /// At or above the low threshold. Capture is unrestricted.
  ample,

  /// Below the low threshold and at or above the critical threshold.
  low,

  /// Below the critical threshold. New capture is refused.
  critical,
}

/// The process-wide [StorageGuard]. Callers never read volume stats themselves.
final Provider<StorageGuard> storageGuardProvider = Provider<StorageGuard>((
  Ref ref,
) {
  return StorageGuard(storageRoot: ref.watch(storageRootProvider));
});

final class _StorageGuard implements StorageGuard {
  _StorageGuard({
    required this._storageRoot,
    required this._freeBytes,
    Stream<AppLifecycleState>? lifecycle,
  }) {
    _output = StreamController<HeadroomState>.broadcast(
      onListen: _replay,
      sync: true,
    );
    if (lifecycle != null) {
      _lifecycleSub = lifecycle.listen(_onLifecycle);
    }
  }

  final StorageRoot _storageRoot;
  final Future<int> Function(Directory root) _freeBytes;

  late final StreamController<HeadroomState> _output;
  StreamSubscription<AppLifecycleState>? _lifecycleSub;

  HeadroomState? _last;
  HeadroomState? _emitted;
  bool _warned = false;
  bool _closed = false;

  @override
  Stream<HeadroomState> watch() => _output.stream;

  @override
  Future<Result<HeadroomState>> check() async {
    try {
      final Result<Directory> root = await _storageRoot.resolve();
      switch (root) {
        case FailureResult<Directory>(:final failure):
          return FailureResult<HeadroomState>(failure);
        case Success<Directory>(:final value):
          final int bytes = await _freeBytes(value);
          final HeadroomState state = _classify(bytes);
          _last = state;
          _emit(state);
          return Success<HeadroomState>(state);
      }
    } on Failure catch (failure) {
      return FailureResult<HeadroomState>(failure);
    } on Object {
      return const FailureResult<HeadroomState>(_unreadable);
    }
  }

  @override
  Future<Result<HeadroomState>> beginSession() {
    _warned = false;
    return check();
  }

  @override
  bool takeLowWarning() {
    if (_last != HeadroomState.low || _warned) {
      return false;
    }
    _warned = true;
    return true;
  }

  @override
  Future<Result<HeadroomState>> admitCapture() async {
    HeadroomState? last = _last;
    if (last == null) {
      final Result<HeadroomState> probed = await check();
      switch (probed) {
        case FailureResult<HeadroomState>(:final failure):
          return FailureResult<HeadroomState>(failure);
        case Success<HeadroomState>(:final value):
          last = value;
      }
    }
    if (last == HeadroomState.critical) {
      return const FailureResult<HeadroomState>(_criticalRefusal);
    }
    return Success<HeadroomState>(last);
  }

  @override
  Future<Result<T>> completeSave<T>(Future<Result<T>> Function() save) {
    return save();
  }

  @override
  Future<void> dispose() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _lifecycleSub?.cancel();
    await _output.close();
  }

  void _onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(check());
    }
  }

  void _replay() {
    final HeadroomState? last = _emitted;
    if (last != null && !_output.isClosed) {
      _output.add(last);
    }
  }

  void _emit(HeadroomState next) {
    if (_closed || _output.isClosed || _emitted == next) {
      return;
    }
    _emitted = next;
    _output.add(next);
  }
}

HeadroomState _classify(int bytes) {
  if (bytes < AppConstants.storage.criticalBytes) {
    return HeadroomState.critical;
  }
  if (bytes < AppConstants.storage.lowBytes) {
    return HeadroomState.low;
  }
  return HeadroomState.ample;
}

Future<int> _platformFreeBytes(Directory root) {
  if (Platform.isWindows) {
    return _windowsFreeBytes(root.path);
  }
  return _posixFreeBytes(root.path);
}

Future<int> _windowsFreeBytes(String path) async {
  final String letter = _windowsDriveLetter(path);
  final ProcessResult result = await Process.run('powershell.exe', <String>[
    '-NoProfile',
    '-NonInteractive',
    '-Command',
    'Write-Output (Get-PSDrive -Name $letter).Free',
  ]);
  final Object? stdout = result.stdout;
  if (result.exitCode != 0 || stdout is! String) {
    throw _unreadable;
  }
  final int? bytes = int.tryParse(stdout.trim());
  if (bytes == null) {
    throw _unreadable;
  }
  return bytes;
}

String _windowsDriveLetter(String path) {
  if (path.length >= 2 && path[1] == ':') {
    final int code = path.codeUnitAt(0);
    if (code >= 65 && code <= 90) {
      return String.fromCharCode(code);
    }
    if (code >= 97 && code <= 122) {
      return String.fromCharCode(code - 32);
    }
  }
  throw _unreadable;
}

Future<int> _posixFreeBytes(String path) async {
  final ProcessResult result = await Process.run('df', <String>['-Pk', path]);
  if (result.exitCode != 0) {
    throw _unreadable;
  }
  final Object? stdout = result.stdout;
  if (stdout is! String) {
    throw _unreadable;
  }
  final List<String> lines = stdout.trim().split(RegExp(r'\r?\n'));
  if (lines.length < 2) {
    throw _unreadable;
  }
  final List<String> parts = lines.last.trim().split(RegExp(r'\s+'));
  final int start = int.tryParse(parts.first) == null ? 1 : 0;
  if (parts.length < start + 3) {
    throw _unreadable;
  }
  final int? kilobytes = int.tryParse(parts[start + 2]);
  if (kilobytes == null) {
    throw _unreadable;
  }
  return kilobytes * 1024;
}

const StorageFailure _criticalRefusal = StorageFailure(
  message: 'There is not enough free space to take another photo.',
  recoveryAction: 'Export a project or clean the cache, then try again.',
);

const StorageFailure _unreadable = StorageFailure(
  message: 'Tapture could not read free space on this device.',
  recoveryAction: 'Free up space or export a project, then try again.',
);

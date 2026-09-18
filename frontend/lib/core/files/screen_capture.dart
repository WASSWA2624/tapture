import 'dart:async';
import 'dart:typed_data';

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'screen_capture_stub.dart'
    if (dart.library.io) 'screen_capture_io.dart'
    if (dart.library.js_interop) 'screen_capture_web.dart'
    as platform;

/// A still of another window or OS surface the operator picks. The browser
/// display picker is reached only here (FE-STR-11); tests use
/// [ScreenCapture.fake]. Native Android, iOS and desktop hide the control.
abstract interface class ScreenCapture {
  /// The service for this platform.
  factory ScreenCapture() => platform.platformScreenCapture();

  /// A stand-in that hands back [frames] in turn, or [failure]. Empty
  /// [frames] and no [frame] is a cancel. Tests never open a display
  /// picker (FE-TEST-03).
  const factory ScreenCapture.fake({
    Uint8List? frame,
    List<Uint8List> frames,
    Failure? failure,
    bool canCapture,
  }) = _FakeScreenCapture;

  /// Whether the Add another window control should show.
  bool get canCapture;

  /// Picks and starts sharing. [Success] false means the operator cancelled.
  Future<Result<bool>> start();

  /// Whether a window is being shared now.
  bool get isSharing;

  /// Fires when sharing stops for any reason, including the browser's Stop sharing.
  Stream<void> get ended;

  /// One PNG of the shared surface now.
  Future<Result<Uint8List>> still({required int longEdge});

  /// Stops every track, and does nothing if nothing is shared.
  void stop();
}

/// Maps a display-picker error onto catalogue copy.
Failure screenCaptureFailure(Object error) {
  final String text = error.toString().toLowerCase();
  if (text.contains('notallowed') ||
      text.contains('permissiondenied') ||
      text.contains('securityerror')) {
    return const PermissionFailure(message: Copy.displayNoAccess);
  }
  return const ProviderFailure(message: Copy.displayCaptureFailed);
}

/// Whether a rejected picker is a cancel rather than a refusal.
bool screenCaptureCancelled(Object error) {
  return error.toString().toLowerCase().contains('aborterror');
}

/// Test access to a fake's stop count and a mid-session end (FE-TEST-03).
extension ScreenCaptureX on ScreenCapture {
  /// How many times [stop] ran on a fake. Always 0 on a live capture.
  int get stops {
    final ScreenCapture capture = this;
    if (capture is _FakeScreenCapture) {
      return _session(capture).stops;
    }
    return 0;
  }

  /// Ends a fake share as the browser's Stop sharing would.
  void end() {
    final ScreenCapture capture = this;
    if (capture is _FakeScreenCapture) {
      _closeShare(capture, countStop: false);
    }
  }
}

final class _FakeScreenCapture implements ScreenCapture {
  const _FakeScreenCapture({
    this.frame,
    this.frames = const <Uint8List>[],
    this.failure,
    this.canCapture = false,
  });

  /// A single still, used when [frames] is empty.
  final Uint8List? frame;

  /// Stills handed out in turn from one session.
  final List<Uint8List> frames;

  /// Why [start] fails, when the picker is refused.
  final Failure? failure;

  @override
  final bool canCapture;

  List<Uint8List> get _queue {
    if (frames.isNotEmpty) {
      return frames;
    }
    final Uint8List? frame = this.frame;
    return frame == null ? const <Uint8List>[] : <Uint8List>[frame];
  }

  @override
  bool get isSharing => _session(this).sharing;

  @override
  Stream<void> get ended => _session(this).ended.stream;

  @override
  Future<Result<bool>> start() async {
    final Failure? failure = this.failure;
    if (failure != null) {
      return FailureResult<bool>(failure);
    }
    if (_queue.isEmpty) {
      return const Success<bool>(false);
    }
    final _FakeSession session = _session(this);
    session.sharing = true;
    session.next = 0;
    return const Success<bool>(true);
  }

  @override
  Future<Result<Uint8List>> still({required int longEdge}) async {
    final _FakeSession session = _session(this);
    if (!session.sharing) {
      return Success<Uint8List>(Uint8List(0));
    }
    final List<Uint8List> queue = _queue;
    if (session.next >= queue.length) {
      return Success<Uint8List>(Uint8List(0));
    }
    return Success<Uint8List>(queue[session.next++]);
  }

  @override
  void stop() {
    _closeShare(this, countStop: true);
  }
}

final class _FakeSession {
  bool sharing = false;
  int next = 0;
  int stops = 0;
  final StreamController<void> ended = StreamController<void>.broadcast();
}

final Expando<_FakeSession> _sessions = Expando<_FakeSession>();

_FakeSession _session(_FakeScreenCapture fake) {
  return _sessions[fake] ??= _FakeSession();
}

void _closeShare(_FakeScreenCapture fake, {required bool countStop}) {
  final _FakeSession session = _session(fake);
  if (!session.sharing) {
    return;
  }
  session.sharing = false;
  if (countStop) {
    session.stops++;
  }
  session.ended.add(null);
}

import 'dart:async';

import 'package:flutter/widgets.dart';

/// The app's only [WidgetsBindingObserver].
///
/// Features listen to [states] instead of registering their own observer
/// (FE-STR-11). Pause flushes are awaited so a background transition cannot
/// lose a write (FE-STATE-07, FE-CODE-07).
class LifecycleObserver with WidgetsBindingObserver {
  /// Creates an observer that awaits [onPauseFlush] when the app backgrounds.
  LifecycleObserver({this.onPauseFlush});

  /// A test double that is never registered with [WidgetsBinding].
  ///
  /// Drive it with [handle] so later tests never touch the platform
  /// (FE-TEST-03).
  factory LifecycleObserver.fake({Future<void> Function()? onPauseFlush}) {
    return LifecycleObserver(onPauseFlush: onPauseFlush);
  }

  /// Called on pause or hidden, and awaited before [handle] completes.
  final Future<void> Function()? onPauseFlush;

  final StreamController<AppLifecycleState> _states =
      StreamController<AppLifecycleState>.broadcast();

  bool _flushed = false;

  Future<void> _inFlight = Future<void>.value();

  /// Lifecycle events as the binding reports them.
  Stream<AppLifecycleState> get states => _states.stream;

  /// Applies [state] as the binding would, awaiting a pause flush.
  Future<void> handle(AppLifecycleState state) async {
    _states.add(state);
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (!_flushed) {
          _flushed = true;
          await onPauseFlush?.call();
        }
      case AppLifecycleState.resumed:
        _flushed = false;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inFlight = handle(state);
  }

  /// Releases the event stream after any in-flight flush. The binding still
  /// holds the observer until [WidgetsBinding.removeObserver] is called.
  void dispose() {
    unawaited(_inFlight.whenComplete(_states.close));
  }
}

import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  final StreamController<void> _memoryPressure =
      StreamController<void>.broadcast();

  bool _flushed = false;

  Future<void> _inFlight = Future<void>.value();

  final List<Future<bool> Function()> _exitChecks = <Future<bool> Function()>[];

  final List<Future<void> Function()> _pauseFlushes =
      <Future<void> Function()>[];

  /// Lifecycle events as the binding reports them.
  Stream<AppLifecycleState> get states => _states.stream;

  /// One event each time the platform asks the app to free memory, so a
  /// holder of a large cache, such as the speech model, can release it.
  Stream<void> get memoryPressure => _memoryPressure.stream;

  /// Registers [check]; a false result cancels the window close.
  void addExitCheck(Future<bool> Function() check) {
    _exitChecks.add(check);
  }

  /// Drops [check] so it no longer runs on a window close.
  void removeExitCheck(Future<bool> Function() check) {
    _exitChecks.remove(check);
  }

  /// Registers [flush], awaited in registration order after [onPauseFlush]
  /// whenever the app is hidden or paused, so [handle] returns only once
  /// it has made its owner's work durable.
  void addPauseFlush(Future<void> Function() flush) {
    _pauseFlushes.add(flush);
  }

  /// Drops [flush] so a later pause no longer awaits it.
  void removePauseFlush(Future<void> Function() flush) {
    _pauseFlushes.remove(flush);
  }

  /// Applies [state] as the binding would, awaiting the pause flushes.
  Future<void> handle(AppLifecycleState state) async {
    _states.add(state);
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (!_flushed) {
          _flushed = true;
          await onPauseFlush?.call();
          for (final Future<void> Function() flush
              in List<Future<void> Function()>.of(_pauseFlushes)) {
            await flush();
          }
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

  /// Forwards the platform's low-memory warning to [memoryPressure].
  @override
  void didHaveMemoryPressure() {
    if (!_memoryPressure.isClosed) {
      _memoryPressure.add(null);
    }
  }

  /// Cancels the close if any registered check returns false.
  @override
  Future<AppExitResponse> didRequestAppExit() async {
    for (final Future<bool> Function() check
        in List<Future<bool> Function()>.of(_exitChecks)) {
      if (!await check()) {
        return AppExitResponse.cancel;
      }
    }
    return AppExitResponse.exit;
  }

  /// Releases the event stream after any in-flight flush. The binding still
  /// holds the observer until [WidgetsBinding.removeObserver] is called.
  void dispose() {
    unawaited(_memoryPressure.close());
    unawaited(_inFlight.whenComplete(_states.close));
  }
}

/// The process-wide observer. [main] replaces this with the instance
/// registered on [WidgetsBinding] so features listen instead of adding a
/// second observer (FE-STR-11).
final Provider<LifecycleObserver> lifecycleObserverProvider =
    Provider<LifecycleObserver>((Ref ref) {
      final LifecycleObserver observer = LifecycleObserver.fake();
      ref.onDispose(observer.dispose);
      return observer;
    });

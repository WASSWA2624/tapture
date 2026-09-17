import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/lifecycle/lifecycle_observer.dart';

/// Errors captured by the temporary handler until the logger (task 022) exists.
@visibleForTesting
final List<Object> debugBootstrapErrors = <Object>[];

LifecycleObserver? _lifecycleObserver;

/// Entry point for the Tapture application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorHandlers();
  _installLifecycleObserver();
  await runZonedGuarded(_run, _handleZoneError);
}

Future<void> _run() async {
  runApp(const ProviderScope(child: TaptureApp()));
}

void _installErrorHandlers() {
  final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    _captureError(details.exception, details.stack ?? StackTrace.empty);
    previous?.call(details);
  };
}

void _installLifecycleObserver() {
  if (_lifecycleObserver != null) {
    return;
  }
  _lifecycleObserver = LifecycleObserver(onPauseFlush: _flushPendingWrites);
  WidgetsBinding.instance.addObserver(_lifecycleObserver!);
}

Future<void> _flushPendingWrites() async {
  // Persistence is not on this task. The await keeps a later flush from
  // becoming a floating future on pause (FE-STATE-07, FE-CODE-07).
}

void _handleZoneError(Object error, StackTrace stackTrace) {
  _captureError(error, stackTrace);
}

void _captureError(Object error, StackTrace stackTrace) {
  debugBootstrapErrors.add(error);
}

import 'dart:async';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';

/// Request options shared with the native transport and injected transports.
final class CloudRequestScope {
  /// Creates a scope. A null token permits cleanup after cancellation.
  const CloudRequestScope({this.cancel, this.timeout, this.authorize});

  /// Cancellation of the currently active request.
  final CancellationToken? cancel;

  /// Maximum idle time, reset whenever request or response bytes move.
  final Duration? timeout;

  /// Rechecks live permissions immediately before constructing a request.
  final FutureOr<void> Function()? authorize;

  /// The options for the current request.
  static CloudRequestScope get current =>
      Zone.current[_key] as CloudRequestScope? ?? const CloudRequestScope();

  /// The effective idle timeout.
  Duration get idleTimeout =>
      timeout ?? AppConstants.cloudUpload.requestTimeout;

  /// Runs an operation in this scope, including its asynchronous work.
  Future<T> run<T>(Future<T> Function() operation) => runZoned(
    operation,
    zoneValues: <Object, Object>{
      _key: CloudRequestScope(
        cancel: cancel,
        timeout: timeout,
        authorize: authorize ?? current.authorize,
      ),
    },
  );

  static final Object _key = Object();
}

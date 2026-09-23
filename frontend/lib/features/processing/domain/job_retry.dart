import 'dart:async';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';

/// Classifies a stage failure and the wait before the next attempt.
///
/// Transient failures — network, timeout, rate limit, provider 5xx — wait.
/// Permanent ones — authentication, an unparseable response after repair,
/// unsupported media, a missing template — stop on the first attempt.
final class JobRetry {
  /// Creates a decision for one failure.
  const JobRetry({
    required this.reason,
    required this.permanent,
    required this.backoff,
  });

  /// Text stored on the job and shown verbatim.
  final String reason;

  /// When true, the job is not claimed again.
  final bool permanent;

  /// How long a transient failure waits. Zero when [permanent].
  final Duration backoff;

  /// Classifies [error]. [attempt] is the count already spent, starting at 1
  /// for the try that just failed. [maxAttempts] comes from settings.
  factory JobRetry.classify(
    Object error, {
    required int attempt,
    int? maxAttempts,
  }) {
    final int cap = maxAttempts ?? AppConstants.processing.maxAttempts;
    final bool transient = _isTransient(error);
    final bool stop = !transient || attempt >= cap;
    return JobRetry(
      reason: _reason(error),
      permanent: stop,
      backoff: stop ? Duration.zero : backoffFor(attempt),
    );
  }

  /// Exponential wait for [attempt], capped so an outage cannot spin.
  static Duration backoffFor(int attempt) {
    final int base = AppConstants.processing.backoffBaseMs;
    final int cap = AppConstants.processing.backoffCapMs;
    final int shift = attempt <= 1 ? 0 : attempt - 1;
    var millis = base;
    for (var i = 0; i < shift; i++) {
      if (millis >= cap) {
        return AppConstants.processingBackoff(cap);
      }
      millis = millis * 2;
    }
    if (millis > cap) {
      millis = cap;
    }
    if (millis < base) {
      millis = base;
    }
    return AppConstants.processingBackoff(millis);
  }

  /// Whether [error] may be tried again before the attempt cap.
  static bool isTransient(Object error) => _isTransient(error);
}

bool _isTransient(Object error) {
  if (error is TimeoutException || error is NetworkFailure) {
    return true;
  }
  if (error is! ProviderFailure) {
    return false;
  }
  final String message = error.message.toLowerCase();
  if (_permanentProvider.hasMatch(message)) {
    return false;
  }
  return _transientProvider.hasMatch(message) ||
      message.contains('unavailable') ||
      message.contains('failed');
}

String _reason(Object error) {
  if (error is Failure) {
    return error.message;
  }
  if (error is TimeoutException) {
    return 'The provider did not answer in time.';
  }
  if (error is FormatException) {
    return 'The provider response could not be read.';
  }
  return 'Processing stopped.';
}

final RegExp _transientProvider = RegExp(
  r'429|rate|timeout|timed out|5\d\d|unavailable|network',
);

final RegExp _permanentProvider = RegExp(
  r'401|403|auth|unauthor|credential|unsupported|template|unparseable|parse',
);

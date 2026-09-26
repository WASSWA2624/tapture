import 'dart:async';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';

/// Classifies a stage failure and the wait before the next attempt.
///
/// The class comes from the failure's type, never from its wording.
/// Transient failures — a [NetworkFailure], a [TimeoutException], and a
/// [ProviderFailure] whose kind is rate limited or unavailable (provider
/// 5xx) — wait and try again. Everything else stops on the first attempt:
/// authentication, unsupported media, a malformed response or one still
/// unparseable after repair ([CorruptionFailure]), a missing template or
/// unreadable media ([ValidationFailure]), and any failure nobody
/// classified, so an unknown error can never spin.
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
  /// for the try that just failed. A transient failure also stops once
  /// [attempt] reaches `AppConstants.processing.maxAttempts`.
  factory JobRetry.classify(Object error, {required int attempt}) {
    final int cap = AppConstants.processing.maxAttempts;
    final bool stop = !_isTransient(error) || attempt >= cap;
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
}

bool _isTransient(Object error) {
  return switch (error) {
    TimeoutException() || NetworkFailure() => true,
    ProviderFailure(:final ProviderFailureKind kind) =>
      kind == ProviderFailureKind.rateLimited ||
          kind == ProviderFailureKind.unavailable,
    _ => false,
  };
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

import 'package:tapture/core/constants/app_constants.dart';

/// Today's online usage against the project's daily cap.
///
/// Reaching the cap blocks further online work and leaves the job queued.
final class CostGuard {
  /// Creates a counter. [requestCap] comes from the settings store.
  const CostGuard({
    required this.requestsToday,
    required this.imagesToday,
    required this.requestCap,
    required this.now,
  });

  /// Extraction requests already made today.
  final int requestsToday;

  /// Images already sent today.
  final int imagesToday;

  /// Requests allowed today.
  final int requestCap;

  /// The instant the counter was read.
  final DateTime now;

  /// Whether another online call must not start.
  bool get isBlocked => requestsToday >= requestCap;

  /// When the counter returns to zero, the next UTC day.
  DateTime get resetsAt {
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).add(AppConstants.processing.dayWindow);
  }

  /// Message naming the cap and when it resets.
  String get blockMessage {
    return "Today's limit of $requestCap requests is used. "
        'It resets at ${resetsAt.toIso8601String()}.';
  }

  /// Adds one request and [images] to today's totals.
  CostGuard record({required int images}) {
    return CostGuard(
      requestsToday: requestsToday + 1,
      imagesToday: imagesToday + images,
      requestCap: requestCap,
      now: now,
    );
  }
}

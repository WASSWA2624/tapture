import 'queue_failure.dart';
import 'queue_failure_cursor.dart';

export 'queue_failure.dart';
export 'queue_failure_cursor.dart';

/// One bounded oldest-first page of queue failures.
final class QueueFailurePage {
  /// Creates a page. A null [nextCursor] means no later failed job exists.
  const QueueFailurePage({
    this.items = const <QueueFailure>[],
    this.nextCursor,
  });

  /// Failed jobs on this page only.
  final List<QueueFailure> items;

  /// Position of the final item when another page exists.
  final QueueFailureCursor? nextCursor;
}

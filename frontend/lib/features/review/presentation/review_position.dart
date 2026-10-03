/// The record the batch review shows, or that it has finished.
final class ReviewPosition {
  /// Creates the position on [current], or at the end when [done].
  const ReviewPosition({this.current, this.done = false});

  /// The record shown; null starts at the first record of the queue.
  final String? current;

  /// Whether the walk has gone past the last record.
  final bool done;

  /// The record shown in [ids], or null at the end or on an empty queue.
  /// A record that left the queue gives way to the first one still in it.
  String? currentIn(List<String> ids) {
    if (done || ids.isEmpty) {
      return null;
    }
    final String? shown = current;
    return shown != null && ids.contains(shown) ? shown : ids.first;
  }

  /// Whether there is a record before the one shown.
  bool canGoBack(List<String> ids) {
    if (done) {
      return ids.isNotEmpty;
    }
    final String? shown = currentIn(ids);
    return shown != null && ids.indexOf(shown) > 0;
  }
}

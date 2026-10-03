import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the captured-item search text.
final class CapturedRecordsQuery extends Notifier<String> {
  @override
  String build() => '';

  /// Replaces the query.
  void set(String value) => state = value;
}

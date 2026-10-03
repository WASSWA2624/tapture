import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the field-list search text.
final class FieldListQuery extends Notifier<String> {
  @override
  String build() => '';

  /// Replaces the query.
  void set(String value) => state = value;
}

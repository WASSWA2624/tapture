import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the template-list search text.
final class TemplateListQuery extends Notifier<String> {
  @override
  String build() => '';

  /// Replaces the query.
  void set(String value) => state = value;
}

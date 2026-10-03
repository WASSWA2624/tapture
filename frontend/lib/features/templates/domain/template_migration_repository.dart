import 'package:tapture/core/errors/result.dart';

import 'template_def.dart';
import 'template_versioning.dart';

/// Watches captured versions and moves the reviewed records atomically.
abstract interface class TemplateMigrationRepository {
  /// Live records belonging to this template, excluding deleted evidence.
  Stream<List<CapturedTemplateRecord>> watch(String templateId);

  /// Counts live records with non-empty captured or proposed values per key.
  /// Aggregates in storage; confirmation does not load the records or values.
  Future<Result<Map<String, int>>> fieldValueCounts(String templateId);

  /// Refuses a stale preview and retains every raw value during migration.
  Future<Result<void>> migrate({
    required TemplateDef template,
    required List<CapturedTemplateRecord> reviewed,
  });
}

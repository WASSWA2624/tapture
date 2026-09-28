import 'package:tapture/core/errors/result.dart';

import 'template_def.dart';
import 'template_versioning.dart';

/// Watches captured versions and moves the reviewed records atomically.
abstract interface class TemplateMigrationRepository {
  /// Live records belonging to this template, excluding deleted evidence.
  Stream<List<CapturedTemplateRecord>> watch(String templateId);

  /// Refuses a stale preview and retains every raw value during migration.
  Future<Result<void>> migrate({
    required TemplateDef template,
    required List<CapturedTemplateRecord> reviewed,
  });
}

import 'dart:async';

import 'package:tapture/core/errors/result.dart';

import 'template_def.dart';

export 'field_def.dart';
export 'template_def.dart';
export 'template_row.dart';

/// Persistence port for templates. Drift types stop at the data layer.
abstract interface class TemplateRepository {
  /// Live templates owned by [projectId], including none when the project is
  /// new.
  Stream<List<TemplateDef>> watchByProject(String projectId);

  /// The template with [id], or null when it is not on this device.
  Future<Result<TemplateDef?>> byId(String id);

  /// Inserts or updates [template] and returns the stored row.
  Future<Result<TemplateDef>> save(TemplateDef template);

  /// Tombstones [id]. [reason] is required so a later audit can say why.
  Future<Result<void>> delete(String id, {required String reason});
}

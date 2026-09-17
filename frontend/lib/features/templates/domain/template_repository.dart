import 'dart:async';

import 'package:tapture/core/errors/result.dart';

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

/// Shape of a record: identity, owning project and structural version.
typedef TemplateDef = ({
  String id,
  String? projectId,
  String name,
  int version,
});

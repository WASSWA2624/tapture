import 'package:tapture/core/errors/result.dart';

/// Which of a project's templates its records were captured with, newest
/// first, so capture lists the templates in the order they are reached for
/// (task 012 step 22).
abstract interface class TemplateUsage {
  /// Template ids of [projectId]'s records, most recently captured with
  /// first. Templates no record has used are absent.
  Future<Result<List<String>>> recentTemplateIds(String projectId);
}

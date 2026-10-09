import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/features/templates/templates.dart';

/// Templates owned by one project. Empty until that project has a template.
final captureProjectTemplatesProvider =
    StreamProvider.family<List<TemplateDef>, String>((
      Ref ref,
      String projectId,
    ) {
      if (projectId.isEmpty) {
        return Stream<List<TemplateDef>>.value(const <TemplateDef>[]);
      }
      return ref.watch(templateRepositoryProvider).watchByProject(projectId);
    });

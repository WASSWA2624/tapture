import 'package:tapture/features/templates/templates.dart';

import '../domain/project_openable_file_lookup.dart';

/// No folder tree: every lookup reports that nothing is there.
ProjectOpenableFileLookup createProjectOpenableFileLookup({
  required TemplateRepository templates,
}) {
  final TemplateRepository _ = templates;
  return ProjectOpenableFileLookup.fake();
}

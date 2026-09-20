import 'package:tapture/features/templates/templates.dart';

import '../domain/project_openable_file_lookup.dart';
import 'project_openable_file_lookup_stub.dart'
    if (dart.library.io) 'project_openable_file_lookup_io.dart'
    as platform;

/// The lookup for this platform. Web and unknown hosts have no folder tree,
/// so they report that no file exists.
ProjectOpenableFileLookup createProjectOpenableFileLookup({
  required TemplateRepository templates,
}) {
  return platform.createProjectOpenableFileLookup(templates: templates);
}

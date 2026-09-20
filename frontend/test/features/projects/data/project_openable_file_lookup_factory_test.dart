import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/projects/data/project_openable_file_lookup_factory.dart';
import 'package:tapture/features/projects/domain/project_openable_file_lookup.dart';

import '../../templates/fakes/fake_template_repository.dart';

void main() {
  test('the factory returns a lookup', () {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    expect(
      createProjectOpenableFileLookup(templates: templates),
      isA<ProjectOpenableFileLookup>(),
    );
  });
}

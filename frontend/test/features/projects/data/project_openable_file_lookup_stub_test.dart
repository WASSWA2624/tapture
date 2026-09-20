import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/projects/data/project_openable_file_lookup_stub.dart';
import 'package:tapture/features/projects/domain/project_openable_file_lookup.dart';

import '../../templates/fakes/fake_template_repository.dart';

void main() {
  test('the stub reports that no file exists', () async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final ProjectOpenableFileLookup lookup = createProjectOpenableFileLookup(
      templates: templates,
    );

    expect(
      _ok(await lookup.exists(projectId: 'project-1', folderName: 'alpha')),
      isFalse,
    );
    expect(
      _ok(await lookup.find(projectId: 'project-1', folderName: 'alpha')),
      isNull,
    );
  });
}

T _ok<T>(Result<T> result) {
  return result.fold((Failure failure) {
    fail('${failure.message} ${failure.recoveryAction}');
  }, (T value) => value);
}

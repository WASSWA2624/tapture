import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/projects/domain/project.dart';
import 'package:tapture/features/projects/domain/project_status.dart';

import '../../../support/factories.dart';

void main() {
  test('copyWith has no folderName entry and leaves it unchanged', () {
    final Project original = aProject(name: 'Alpha');
    final Project renamed = original.copyWith(
      name: 'Alpha Renamed',
      description: 'Note',
      organisation: 'Acme',
      status: ProjectStatus.archived,
    );
    expect(renamed.folderName, original.folderName);
    expect(renamed.id, original.id);
    expect(renamed.name, 'Alpha Renamed');
    expect(renamed.description, 'Note');
    expect(renamed.organisation, 'Acme');
    expect(renamed.status, ProjectStatus.archived);
    expect(renamed.createdAt, original.createdAt);
  });

  test('only an active project is included in default exports', () {
    expect(aProject().includedInDefaultExports, isTrue);
    expect(
      aProject()
          .copyWith(status: ProjectStatus.archived)
          .includedInDefaultExports,
      isFalse,
    );
    expect(
      aProject()
          .copyWith(status: ProjectStatus.deleted)
          .includedInDefaultExports,
      isFalse,
    );
  });
}

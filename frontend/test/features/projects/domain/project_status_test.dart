import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/projects/domain/project_status.dart';

void main() {
  test('names the three lifecycle states', () {
    expect(ProjectStatus.values, <ProjectStatus>[
      ProjectStatus.active,
      ProjectStatus.archived,
      ProjectStatus.deleted,
    ]);
  });
}

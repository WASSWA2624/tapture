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
    expect(renamed.pinnedAt, original.pinnedAt);
  });

  test('copyWith keeps a pin unless a new timestamp is given', () {
    final DateTime pin = DateTime.utc(2026, 9, 18, 12);
    final Project pinned = aProject(pinnedAt: pin);
    expect(pinned.copyWith(name: 'Renamed').pinnedAt, pin);
    expect(
      pinned.copyWith(pinnedAt: DateTime.utc(2026, 9, 19)).pinnedAt,
      DateTime.utc(2026, 9, 19),
    );
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

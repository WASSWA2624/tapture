import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/projects.dart' as projects_db;
import 'package:tapture/features/projects/data/project_mapper.dart';
import 'package:tapture/features/projects/domain/project.dart';
import 'package:tapture/features/projects/domain/project_settings.dart';
import 'package:tapture/features/projects/domain/project_status.dart';

void main() {
  test('row → Project → row keeps every mapped column', () {
    final DateTime started = DateTime.utc(2026, 1, 2);
    final DateTime ended = DateTime.utc(2026, 6, 30);
    final sqlite.Project row = _row(
      client: 'Acme Health',
      startedAt: started,
      completedAt: ended,
      pinnedAt: DateTime.utc(2026, 9, 18, 12),
      settings: jsonEncode(<String, Object?>{
        'aiEnabled': false,
        'doNotSendImages': true,
        'gpsEnabled': true,
        'folderStrategy': 'byTemplate',
        'confidenceHigh': 0.9,
        'confidenceMedium': 0.5,
        'refineColumns': false,
        'description': '  Field inventory  ',
      }),
    );

    final Project project = ProjectMapper.fromRow(row);
    expect(project.id, row.id);
    expect(project.name, 'Alpha');
    expect(project.organisation, 'Acme Health');
    expect(project.description, 'Field inventory');
    expect(project.status, ProjectStatus.active);
    expect(project.startsOn, started);
    expect(project.endsOn, ended);
    expect(project.pinnedAt, DateTime.utc(2026, 9, 18, 12));
    expect(project.folderName, 'alpha-1');
    expect(project.settings.aiEnabled, isFalse);
    expect(project.settings.doNotSendImages, isTrue);
    expect(project.settings.gpsEnabled, isTrue);
    expect(project.settings.folderStrategy, 'byTemplate');
    expect(project.settings.confidenceHigh, 0.9);
    expect(project.settings.confidenceMedium, 0.5);
    expect(project.settings.refineColumns, isFalse);

    final sqlite.ProjectsCompanion companion = ProjectMapper.toRow(project);
    expect(companion.id.value, row.id);
    expect(companion.name.value, row.name);
    expect(companion.client.value, 'Acme Health');
    expect(companion.folderName.value, row.folderName);
    expect(companion.status.value, projects_db.ProjectStatus.active);
    expect(companion.startedAt.value, started);
    expect(companion.completedAt.value, ended);
    expect(companion.pinnedAt.value, DateTime.utc(2026, 9, 18, 12));

    final Object? encoded = jsonDecode(companion.settings.value);
    expect(encoded, isA<Map<Object?, Object?>>());
    final Map<Object?, Object?> settings = encoded! as Map<Object?, Object?>;
    expect(settings['description'], 'Field inventory');
    expect(settings['aiEnabled'], isFalse);
    expect(settings['folderStrategy'], 'byTemplate');

    final sqlite.Project written = row.copyWithCompanion(companion);
    expect(ProjectMapper.fromRow(written), project);
  });

  test('unknown or missing settings JSON loads as defaults', () {
    expect(
      ProjectMapper.fromRow(_row(settings: '{')).settings,
      ProjectSettings.defaults,
    );
    expect(
      ProjectMapper.fromRow(_row(settings: '')).settings,
      ProjectSettings.defaults,
    );
    expect(
      ProjectMapper.fromRow(_row(settings: '[]')).settings,
      ProjectSettings.defaults,
    );
    expect(
      ProjectMapper.fromRow(_row(settings: '{"nope": true}')).settings,
      ProjectSettings.defaults,
    );
    expect(ProjectMapper.fromRow(_row(client: '')).organisation, isNull);
    expect(ProjectMapper.fromRow(_row()).description, isNull);
    expect(ProjectMapper.fromRow(_row()).settings.folderStrategy, isNull);
    expect(ProjectMapper.fromRow(_row()).pinnedAt, isNull);
  });
}

sqlite.Project _row({
  String client = 'Acme',
  String settings = '{}',
  DateTime? startedAt,
  DateTime? completedAt,
  DateTime? pinnedAt,
}) {
  final DateTime at = DateTime.utc(2026, 9, 17, 8);
  return sqlite.Project(
    id: 'project-1',
    createdAt: at,
    updatedAt: at,
    updatedByDevice: 'device-test',
    rev: 1,
    name: 'Alpha',
    client: client,
    status: projects_db.ProjectStatus.active,
    startedAt: startedAt,
    completedAt: completedAt,
    folderName: 'alpha-1',
    settings: settings,
    pinnedAt: pinnedAt,
  );
}

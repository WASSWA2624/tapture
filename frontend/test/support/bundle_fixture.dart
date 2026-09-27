import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/files/storage_root.dart';

import 'factories.dart';

/// A project worth packaging, one line of setup (FE-TEST-04): the seeded
/// project of [seededDatabase] with [records] records and their photo
/// files on disk, a cover photo, a context level, a template field that
/// looks up a global dataset, field values, captions, audit rows, a
/// tombstone, and an operator profile holding a secret-shaped preference.
/// A second project and an unused global dataset sit beside it and must
/// never travel with it.
typedef BundleFixture = ({
  sqlite.AppDatabase db,
  StorageRoot storageRoot,
  Directory root,
  String projectId,
  String folderName,
  Map<String, Uint8List> files,
  String secret,
});

/// Builds a [BundleFixture] under a fresh temporary folder.
Future<BundleFixture> seedProjectForBundle({int records = 2}) async {
  final sqlite.AppDatabase db = await seededDatabase(records: records);
  final Directory documents = Directory.systemTemp.createTempSync(
    'tapture-bundle-',
  );
  final Directory root = Directory('${documents.path}/Tapture')
    ..createSync(recursive: true);
  final StorageRoot storageRoot = StorageRoot.fake(
    documentsDirectory: documents,
  );
  final Map<String, Object?> project =
      (await db.customSelect('SELECT * FROM projects LIMIT 1').getSingle())
          .data;
  final String projectId = project['id']! as String;
  final String folder = project['folder_name']! as String;
  final String templateId =
      (await db.customSelect('SELECT id FROM templates LIMIT 1').getSingle())
              .data['id']!
          as String;
  final List<Map<String, Object?>> photos = <Map<String, Object?>>[
    for (final QueryRow row
        in await db.customSelect('SELECT * FROM photos ORDER BY id').get())
      row.data,
  ];
  final List<String> recordIds = <String>[
    for (final QueryRow row
        in await db.customSelect('SELECT id FROM records ORDER BY id').get())
      row.data['id']! as String,
  ];
  final Map<String, Uint8List> files = <String, Uint8List>{};
  for (int index = 0; index < photos.length; index++) {
    final String path = photos[index]['relative_path']! as String;
    files[path] = Uint8List.fromList(
      List<int>.generate(4000 + index, (int i) => (i * 7 + index) % 256),
    );
  }
  files['cover/cover-1.jpg'] = Uint8List.fromList(
    List<int>.generate(900, (int i) => i % 251),
  );
  for (final MapEntry<String, Uint8List> file in files.entries) {
    File('${root.path}/projects/$folder/${file.key}')
      ..createSync(recursive: true)
      ..writeAsBytesSync(file.value);
  }
  await db.customStatement(
    'UPDATE projects SET settings = ? WHERE id = ?',
    <Object>[
      jsonEncode(<String, Object?>{
        'description': 'A seeded site',
        'coverPhoto': <String, Object?>{
          'path': 'projects/$folder/cover/cover-1.jpg',
          'sha256': 'cover-sha',
        },
      }),
      projectId,
    ],
  );
  await insertRow(db, 'template_fields', <String, Object?>{
    'id': 'field-serial',
    'template_id': templateId,
    'field_key': 'serial_number',
    'label': 'Serial number',
    'type': 'text',
    'sort_order': 0,
    'lookup': jsonEncode(<String, Object?>{'datasetId': 'ds-global'}),
  });
  await db.customStatement(
    'UPDATE templates SET detection = ? WHERE id = ?',
    <Object>[
      jsonEncode(<String, Object?>{'template_key': 'seeded_equipment'}),
      templateId,
    ],
  );
  await insertRow(db, 'context_definitions', <String, Object?>{
    'id': 'level-district',
    'project_id': projectId,
    'level': 0,
    'field_key': 'district',
    'label': 'District',
  });
  for (final String dataset in <String>['ds-global', 'ds-other']) {
    await insertRow(db, 'reference_datasets', <String, Object?>{
      'id': dataset,
      'name': dataset,
      'key_column': 'code',
      'columns': '[]',
    });
    await insertRow(db, 'reference_rows', <String, Object?>{
      'id': 'row-$dataset',
      'dataset_id': dataset,
      'key_value': 'K1',
      'key_normalised': 'k1',
      'values': '{}',
    });
  }
  for (int index = 0; index < recordIds.length; index++) {
    await insertRow(db, 'record_fields', <String, Object?>{
      'id': 'value-$index',
      'record_id': recordIds[index],
      'field_key': 'serial_number',
      'value_raw': 'SN-$index',
    });
    await insertRow(db, 'captions', <String, Object?>{
      'id': 'caption-$index',
      'owner_type': 'record',
      'owner_id': recordIds[index],
      'text_raw': 'Pump $index, working',
      'input_mode': 'typed',
    });
    await insertRow(db, 'audit_log', <String, Object?>{
      'id': 'audit-$index',
      'entity_type': 'records',
      'entity_id': recordIds[index],
      'action': 'created',
      'operator': 'Ada',
      'device': 'device-test',
      'at': 1790000000,
    });
  }
  if (recordIds.length > 1) {
    await insertRow(db, 'tombstones', <String, Object?>{
      'id': 'tomb-1',
      'entity_type': 'records',
      'entity_id': recordIds.last,
      'deleted_at': 1790000100,
      'deleted_by_device': 'device-test',
      'reason': 'duplicate',
    });
  }
  await insertRow(db, 'projects', <String, Object?>{
    'id': 'project-other',
    'name': 'Other project',
    'status': 'active',
    'folder_name': 'other-project',
    'settings': '{}',
  });
  await insertRow(db, 'records', <String, Object?>{
    'id': 'record-other',
    'project_id': 'project-other',
    'template_id': templateId,
    'status': 'captured',
  });
  await insertRow(db, 'audit_log', <String, Object?>{
    'id': 'audit-other',
    'entity_type': 'records',
    'entity_id': 'record-other',
    'action': 'created',
    'operator': 'Ben',
    'device': 'device-test',
    'at': 1790000000,
  });
  const String secret = 'sk-live-SECRETSECRETSECRET1234';
  await insertRow(db, 'device_profile', <String, Object?>{
    'id': 'local',
    'device_id': 'device-test',
    'operator_name': 'Ada',
    'preferences': jsonEncode(<String, Object?>{'apiKey': secret}),
  });
  return (
    db: db,
    storageRoot: storageRoot,
    root: root,
    projectId: projectId,
    folderName: folder,
    files: files,
    secret: secret,
  );
}

/// Inserts [values] into [table], filling every other NOT NULL column that
/// has no default with an empty value of its declared type, so a fixture
/// states only what a test reads. The merge columns get fixed values.
Future<void> insertRow(
  GeneratedDatabase db,
  String table,
  Map<String, Object?> values,
) async {
  final Map<String, Object?> row = <String, Object?>{
    'created_at': 1790000000,
    'updated_at': 1790000000,
    'updated_by_device': 'device-test',
    'rev': 1,
    ...values,
  };
  for (final QueryRow column
      in await db.customSelect('PRAGMA table_info($table)').get()) {
    final String name = column.data['name']! as String;
    final bool required =
        column.data['notnull'] == 1 && column.data['dflt_value'] == null;
    if (!required || row.containsKey(name)) {
      continue;
    }
    final String type = (column.data['type'] as String? ?? '').toUpperCase();
    row[name] = type.contains('INT')
        ? 0
        : type.contains('REAL')
        ? 0.0
        : '';
  }
  final List<String> names = row.keys.toList();
  await db.customStatement(
    'INSERT INTO $table (${names.map((String n) => '"$n"').join(', ')}) '
    'VALUES (${List<String>.filled(names.length, '?').join(', ')})',
    <Object?>[for (final String name in names) row[name]],
  );
}

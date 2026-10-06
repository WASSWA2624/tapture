import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:image/image.dart' as image;
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
  // This owned seeding operation never alters schema. Reuse only its live
  // metadata; ordinary insertRow callers still inspect every current table.
  final Map<String, Map<String, Object>> requiredColumns =
      <String, Map<String, Object>>{};
  Future<void> insert(String table, Map<String, Object?> values) async {
    final Map<String, Object> columns = requiredColumns[table] ??=
        await _requiredColumns(db, table);
    await _insertRow(db, table, values, columns);
  }

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
    final Uint8List bytes = _photoBytes(index + 1);
    files[path] = bytes;
    await db.customStatement(
      'UPDATE photos SET sha256 = ?, file_size = ?, width = 32, height = 32 WHERE id = ?',
      <Object?>[
        sha256.convert(bytes).toString(),
        bytes.length,
        photos[index]['id'],
      ],
    );
  }
  files['cover/cover-1.jpg'] = _photoBytes(65535);
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
          'sha256': sha256.convert(files['cover/cover-1.jpg']!).toString(),
        },
      }),
      projectId,
    ],
  );
  await insert('template_fields', <String, Object?>{
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
  await insert('context_definitions', <String, Object?>{
    'id': 'level-district',
    'project_id': projectId,
    'level': 0,
    'field_key': 'district',
    'label': 'District',
  });
  for (final String dataset in <String>['ds-global', 'ds-other']) {
    await insert('reference_datasets', <String, Object?>{
      'id': dataset,
      'name': dataset,
      'key_column': 'code',
      'columns': '[]',
    });
    await insert('reference_rows', <String, Object?>{
      'id': 'row-$dataset',
      'dataset_id': dataset,
      'key_value': 'K1',
      'key_normalised': 'k1',
      'values': '{}',
    });
  }
  for (int index = 0; index < recordIds.length; index++) {
    await insert('record_fields', <String, Object?>{
      'id': 'value-$index',
      'record_id': recordIds[index],
      'field_key': 'serial_number',
      'value_raw': 'SN-$index',
    });
    await insert('captions', <String, Object?>{
      'id': 'caption-$index',
      'owner_type': 'record',
      'owner_id': recordIds[index],
      'text_raw': 'Pump $index, working',
      'input_mode': 'typed',
    });
    await insert('audit_log', <String, Object?>{
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
    await insert('tombstones', <String, Object?>{
      'id': 'tomb-1',
      'entity_type': 'records',
      'entity_id': recordIds.last,
      'deleted_at': 1790000100,
      'deleted_by_device': 'device-test',
      'reason': 'duplicate',
    });
  }
  await insert('projects', <String, Object?>{
    'id': 'project-other',
    'name': 'Other project',
    'status': 'active',
    'folder_name': 'other-project',
    'settings': '{}',
  });
  await insert('records', <String, Object?>{
    'id': 'record-other',
    'project_id': 'project-other',
    'template_id': templateId,
    'status': 'captured',
  });
  await insert('audit_log', <String, Object?>{
    'id': 'audit-other',
    'entity_type': 'records',
    'entity_id': 'record-other',
    'action': 'created',
    'operator': 'Ben',
    'device': 'device-test',
    'at': 1790000000,
  });
  const String secret = 'sk-live-SECRETSECRETSECRET1234';
  await insert('device_profile', <String, Object?>{
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

/// Distinct high-contrast tiles survive JPEG encoding and privacy decoding.
Uint8List _photoBytes(int seed) {
  final image.Image photo = image.Image(width: 32, height: 32);
  for (int y = 0; y < photo.height; y++) {
    for (int x = 0; x < photo.width; x++) {
      final int bit = (y ~/ 8) * 4 + x ~/ 8;
      final int shade = ((seed >> bit) & 1) == 1 ? 220 : 30;
      photo.setPixelRgb(x, y, shade, shade, shade);
    }
  }
  return image.encodeJpg(photo, quality: 90);
}

/// Inserts [values] into [table], filling every other NOT NULL column that
/// has no default with an empty value of its declared type, so a fixture
/// states only what a test reads. The merge columns get fixed values.
Future<void> insertRow(
  GeneratedDatabase db,
  String table,
  Map<String, Object?> values,
) async {
  await _insertRow(db, table, values, await _requiredColumns(db, table));
}

Future<Map<String, Object>> _requiredColumns(
  GeneratedDatabase db,
  String table,
) async {
  final Map<String, Object> required = <String, Object>{};
  for (final QueryRow column
      in await db.customSelect('PRAGMA table_info($table)').get()) {
    if (column.data['notnull'] != 1 || column.data['dflt_value'] != null) {
      continue;
    }
    final String type = (column.data['type'] as String? ?? '').toUpperCase();
    required[column.read<String>('name')] = type.contains('INT')
        ? 0
        : type.contains('REAL')
        ? 0.0
        : '';
  }
  return required;
}

Future<void> _insertRow(
  GeneratedDatabase db,
  String table,
  Map<String, Object?> values,
  Map<String, Object> required,
) async {
  final Map<String, Object?> row = <String, Object?>{
    'created_at': 1790000000,
    'updated_at': 1790000000,
    'updated_by_device': 'device-test',
    'rev': 1,
    ...values,
  };
  for (final MapEntry<String, Object> column in required.entries) {
    row.putIfAbsent(column.key, () => column.value);
  }
  final List<String> names = row.keys.toList();
  await db.customStatement(
    'INSERT INTO $table (${names.map((String n) => '"$n"').join(', ')}) '
    'VALUES (${List<String>.filled(names.length, '?').join(', ')})',
    <Object?>[for (final String name in names) row[name]],
  );
}

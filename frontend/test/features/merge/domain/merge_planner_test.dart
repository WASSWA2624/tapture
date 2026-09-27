import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/domain.dart';

/// Tables as a package carries them, in a line each (FE-TEST-04).
typedef Tables = Map<String, List<Map<String, Object?>>>;

void main() {
  Map<String, Object?> record(
    String id, {
    String project = 'p1',
    String template = 't1',
    String status = 'captured',
    int updatedAt = 100,
  }) => <String, Object?>{
    'id': id,
    'project_id': project,
    'template_id': template,
    'status': status,
    'updated_at': updatedAt,
    'updated_by_device': 'dev',
    'rev': 1,
  };

  Map<String, Object?> value(
    String id,
    String recordId,
    String? raw, {
    String key = 'serial',
    String? finalValue,
    bool verified = false,
    String source = 'TYPED',
    int rev = 1,
  }) => <String, Object?>{
    'id': id,
    'record_id': recordId,
    'field_key': key,
    'value_raw': raw,
    'value_final': finalValue,
    'verified': verified ? 1 : 0,
    'source': source,
    'rev': rev,
    'updated_at': 100,
    'updated_by_device': 'dev',
  };

  Map<String, Object?> photo(
    String id,
    String recordId,
    String sha, {
    String path = 'photos/a.jpg',
  }) => <String, Object?>{
    'id': id,
    'project_id': 'p1',
    'record_id': recordId,
    'relative_path': path,
    'sha256': sha,
    'updated_at': 100,
  };

  Map<String, Object?> tomb(String table, String id, int at) =>
      <String, Object?>{
        'id': 'tomb-$id',
        'entity_type': table,
        'entity_id': id,
        'deleted_at': at,
        'deleted_by_device': 'dev',
      };

  MergePlan plan(
    Tables incoming,
    Tables local, {
    String target = 'p1',
    String source = 'p1',
    Map<String, String> mapping = const <String, String>{'t1': 't1'},
    Map<String, Set<String>> elsewhere = const <String, Set<String>>{},
    Set<String> skip = const <String>{},
    Set<String> decided = const <String>{},
  }) {
    return MergePlanner.plan(
      incoming: incoming,
      local: local,
      templateMapping: mapping,
      targetProjectId: target,
      incomingProjectId: source,
      elsewhere: elsewhere,
      skipRecords: skip,
      decided: decided,
    );
  }

  group('records', () {
    test('a record absent here is inserted into the target project under '
        'the matched template', () {
      final MergePlan result = plan(
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[
            record('r1', project: 'p9', template: 't9'),
          ],
          'record_fields': <Map<String, Object?>>[value('v1', 'r1', 'A')],
        },
        <String, List<Map<String, Object?>>>{},
        source: 'p9',
        mapping: const <String, String>{'t9': 't1'},
      );
      final Map<String, Object?> inserted = result.inserts['records']!.single;
      expect(inserted['project_id'], 'p1');
      expect(inserted['template_id'], 't1');
      expect(result.inserts['record_fields'], hasLength(1));
      expect(result.counts.newRecords, 1);
      expect(result.insertedRecords, <String>['r1']);
    });

    test('identical content gives an empty plan', () {
      final Tables tables = <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[record('r1')],
        'record_fields': <Map<String, Object?>>[value('v1', 'r1', 'A')],
        'photos': <Map<String, Object?>>[photo('ph1', 'r1', 'sha1')],
      };
      expect(plan(tables, tables).isEmpty, isTrue);
    });

    test('a record under an unmatched template is left out', () {
      final MergePlan result = plan(
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('r1', template: 't9')],
        },
        <String, List<Map<String, Object?>>>{},
        source: 'p9',
      );
      expect(result.inserts['records'], isNull);
    });

    test('a record deleted on the other device and never here is not '
        'brought in', () {
      final MergePlan result = plan(<String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[record('r1')],
        'tombstones': <Map<String, Object?>>[tomb('records', 'r1', 200)],
      }, <String, List<Map<String, Object?>>>{});
      expect(result.isEmpty, isTrue);
    });

    test('a differing status is a conflict', () {
      final MergePlan result = plan(
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('r1', status: 'approved')],
        },
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('r1')],
        },
      );
      final FieldConflict conflict = result.conflicts.single;
      expect(conflict.kind, ConflictKind.status);
      expect(conflict.mine, 'captured');
      expect(conflict.theirs, 'approved');
    });

    test('a legacy spelling of the same status from a peer is no conflict', () {
      final MergePlan result = plan(
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[
            record('r1', status: 'NEEDS_REVIEW'),
          ],
        },
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[
            record('r1', status: 'needsReview'),
          ],
        },
      );
      expect(result.conflicts, isEmpty);
      expect(result.isEmpty, isTrue);
    });

    test('a differing status is raised in its stored spelling', () {
      final MergePlan result = plan(
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('r1', status: 'APPROVED')],
        },
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('r1', status: 'CAPTURED')],
        },
      );
      final FieldConflict conflict = result.conflicts.single;
      expect(conflict.mine, 'captured');
      expect(conflict.theirs, 'approved');
    });

    test('rows held in another project here are skipped and counted', () {
      final MergePlan result = plan(
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('r1')],
        },
        <String, List<Map<String, Object?>>>{},
        elsewhere: const <String, Set<String>>{
          'records': <String>{'r1'},
        },
      );
      expect(result.inserts['records'], isNull);
      expect(result.counts.elsewhere, 1);
    });

    test('a record a person chose not to import brings nothing', () {
      final MergePlan result = plan(
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('r1')],
          'record_fields': <Map<String, Object?>>[value('v1', 'r1', 'A')],
          'photos': <Map<String, Object?>>[photo('ph1', 'r1', 'sha1')],
        },
        <String, List<Map<String, Object?>>>{},
        skip: const <String>{'r1'},
      );
      expect(result.isEmpty, isTrue);
      expect(result.files, isEmpty);
    });
  });

  group('field values follow the rules in order', () {
    Tables side(Map<String, Object?> field) =>
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('r1')],
          'record_fields': <Map<String, Object?>>[field],
        };

    test('a verified value beats an unverified one, either way', () {
      final MergePlan taken = plan(
        side(value('v1', 'r1', 'A', finalValue: 'B', verified: true)),
        side(value('v1', 'r1', 'A', finalValue: 'C', rev: 3)),
      );
      expect(taken.settled.single.rule, SettlementRule.verifiedBeatsUnverified);
      expect(taken.settled.single.value, 'B');
      final MergePlan kept = plan(
        side(value('v1', 'r1', 'A', finalValue: 'C', rev: 3)),
        side(value('v1', 'r1', 'A', finalValue: 'B', verified: true)),
      );
      expect(kept.settled, isEmpty);
      expect(kept.counts.kept, 1);
    });

    test('a scanned value beats one read by OCR', () {
      final MergePlan result = plan(
        side(value('v1', 'r1', 'X-1', source: 'barcode', rev: 2)),
        side(value('v1', 'r1', 'X-l', source: 'ocr', rev: 2)),
      );
      expect(result.settled.single.rule, SettlementRule.scannedBeatsInferred);
      expect(result.settled.single.value, 'X-1');
    });

    test('a value beats an empty one nobody edited', () {
      final MergePlan result = plan(
        side(value('v1', 'r1', 'A')),
        side(value('v1', 'r1', null)),
      );
      expect(
        result.settled.single.rule,
        SettlementRule.valueBeatsUntouchedEmpty,
      );
    });

    test('anything else is a conflict for a person', () {
      final MergePlan result = plan(
        side(value('v1', 'r1', 'A', finalValue: 'B', rev: 2)),
        side(value('v1', 'r1', 'A', finalValue: 'C', rev: 2)),
      );
      final FieldConflict conflict = result.conflicts.single;
      expect(conflict.kind, ConflictKind.value);
      expect(conflict.mine, 'C');
      expect(conflict.theirs, 'B');
      expect(conflict.id, 'value:record_fields:v1');
    });

    test('a conflict a person already settled for this device is not '
        'raised again', () {
      final MergePlan result = plan(
        side(value('v1', 'r1', 'A', finalValue: 'B', rev: 2)),
        side(value('v1', 'r1', 'A', finalValue: 'C', rev: 2)),
        decided: const <String>{'value:record_fields:v1|B'},
      );
      expect(result.conflicts, isEmpty);
      expect(result.counts.kept, 1);
    });

    test('the same field under another id matches by record and key', () {
      final MergePlan result = plan(
        side(value('v-there', 'r1', 'A')),
        side(value('v-here', 'r1', 'A')),
      );
      expect(result.isEmpty, isTrue);
    });
  });

  group('photos', () {
    test('the same id is the same photo; the same content under another '
        'id is already here', () {
      final MergePlan result = plan(
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('r1')],
          'photos': <Map<String, Object?>>[
            photo('ph1', 'r1', 'sha1'),
            photo('ph2', 'r1', 'sha2', path: 'photos/b.jpg'),
          ],
        },
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('r1')],
          'photos': <Map<String, Object?>>[
            photo('ph1', 'r1', 'sha1'),
            photo('ph-here', 'r1', 'sha2', path: 'photos/c.jpg'),
          ],
        },
      );
      expect(result.inserts['photos'], isNull);
      expect(result.counts.photosHere, 1);
    });

    test('a path another file holds moves under _merged', () {
      final MergePlan result = plan(
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('r1')],
          'photos': <Map<String, Object?>>[photo('ph2', 'r1', 'sha2')],
        },
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('r1')],
          'photos': <Map<String, Object?>>[photo('ph1', 'r1', 'sha1')],
        },
      );
      expect(result.files.single.entry, 'photos/a.jpg');
      expect(result.files.single.target, 'photos/_merged/ph2.jpg');
      expect(
        result.inserts['photos']!.single['relative_path'],
        'photos/_merged/ph2.jpg',
      );
      expect(result.counts.newPhotos, 1);
    });
  });

  group('tombstones', () {
    Tables withRecord({
      int updatedAt = 100,
      List<Map<String, Object?>>? tombs,
    }) => <String, List<Map<String, Object?>>>{
      'records': <Map<String, Object?>>[record('r1', updatedAt: updatedAt)],
      'tombstones': ?tombs,
    };

    test('an incoming delete applies when nothing changed here since', () {
      final MergePlan result = plan(
        withRecord(tombs: <Map<String, Object?>>[tomb('records', 'r1', 200)]),
        withRecord(),
      );
      expect(result.inserts['tombstones'], hasLength(1));
      expect(result.counts.deletions, 1);
    });

    test('an incoming delete of a record changed here since is a conflict', () {
      final MergePlan result = plan(
        withRecord(tombs: <Map<String, Object?>>[tomb('records', 'r1', 200)]),
        withRecord(updatedAt: 300),
      );
      expect(result.conflicts.single.kind, ConflictKind.deletedThere);
      expect(result.inserts['tombstones'], isNull);
    });

    test('a delete here holds when the other device changed nothing since', () {
      final MergePlan result = plan(
        withRecord(),
        withRecord(tombs: <Map<String, Object?>>[tomb('records', 'r1', 200)]),
      );
      expect(result.conflicts, isEmpty);
      expect(result.counts.kept, 1);
    });

    test('a delete here of a record changed there since is a conflict', () {
      final MergePlan result = plan(
        withRecord(updatedAt: 300),
        withRecord(tombs: <Map<String, Object?>>[tomb('records', 'r1', 200)]),
      );
      final FieldConflict conflict = result.conflicts.single;
      expect(conflict.kind, ConflictKind.deletedHere);
      expect(conflict.rowId, 'r1');
    });
  });

  group('project structure', () {
    test('context levels union by key and append; presets union by name', () {
      final MergePlan result = plan(
        <String, List<Map<String, Object?>>>{
          'context_definitions': <Map<String, Object?>>[
            <String, Object?>{'id': 'c1', 'field_key': 'site', 'level': 0},
            <String, Object?>{'id': 'c9', 'field_key': 'room', 'level': 1},
          ],
          'context_presets': <Map<String, Object?>>[
            <String, Object?>{'id': 'pr9', 'name': 'Block A'},
            <String, Object?>{'id': 'pr8', 'name': 'Block B'},
          ],
        },
        <String, List<Map<String, Object?>>>{
          'context_definitions': <Map<String, Object?>>[
            <String, Object?>{'id': 'c2', 'field_key': 'site', 'level': 0},
            <String, Object?>{'id': 'c3', 'field_key': 'floor', 'level': 1},
          ],
          'context_presets': <Map<String, Object?>>[
            <String, Object?>{'id': 'pr1', 'name': 'Block A'},
          ],
        },
      );
      final Map<String, Object?> level =
          result.inserts['context_definitions']!.single;
      expect(level['field_key'], 'room');
      expect(level['level'], 2);
      expect(result.inserts['context_presets']!.single['name'], 'Block B');
    });

    test('the same project brings a template it lacks; another project '
        'only maps', () {
      final Tables incoming = <String, List<Map<String, Object?>>>{
        'templates': <Map<String, Object?>>[
          <String, Object?>{'id': 't2', 'name': 'New'},
        ],
        'template_fields': <Map<String, Object?>>[
          <String, Object?>{'id': 'f2', 'template_id': 't2'},
        ],
        'records': <Map<String, Object?>>[record('r2', template: 't2')],
      };
      final MergePlan same = plan(
        incoming,
        <String, List<Map<String, Object?>>>{},
        mapping: const <String, String>{},
      );
      expect(same.inserts['templates'], hasLength(1));
      expect(same.inserts['template_fields'], hasLength(1));
      expect(same.inserts['records']!.single['template_id'], 't2');
      final MergePlan other = plan(
        incoming,
        <String, List<Map<String, Object?>>>{},
        source: 'p9',
        mapping: const <String, String>{},
      );
      expect(other.inserts['templates'], isNull);
      expect(other.inserts['records'], isNull);
    });

    test('the project row never merges; its differing details are listed '
        'for the same project only', () {
      final Tables incoming = <String, List<Map<String, Object?>>>{
        'projects': <Map<String, Object?>>[
          <String, Object?>{'id': 'p1', 'name': 'Pumps north', 'client': 'X'},
        ],
      };
      final Tables local = <String, List<Map<String, Object?>>>{
        'projects': <Map<String, Object?>>[
          <String, Object?>{'id': 'p1', 'name': 'Pumps', 'client': 'X'},
        ],
      };
      final MergePlan same = plan(incoming, local);
      expect(same.projectKept, <String>['name']);
      expect(same.isEmpty, isTrue);
      expect(same.inserts['projects'], isNull);
      expect(plan(incoming, local, source: 'p9').projectKept, isEmpty);
    });

    test('reference rows add absent keys and keep this device\'s values', () {
      final MergePlan result = plan(
        <String, List<Map<String, Object?>>>{
          'reference_datasets': <Map<String, Object?>>[
            <String, Object?>{'id': 'ds', 'name': 'Staff'},
          ],
          'reference_rows': <Map<String, Object?>>[
            <String, Object?>{
              'id': 'rr1',
              'dataset_id': 'ds',
              'key_value': 'K1',
              'values': '{"name":"There"}',
            },
            <String, Object?>{
              'id': 'rr2',
              'dataset_id': 'ds',
              'key_value': 'K2',
              'values': '{}',
            },
          ],
        },
        <String, List<Map<String, Object?>>>{
          'reference_datasets': <Map<String, Object?>>[
            <String, Object?>{'id': 'ds', 'name': 'Staff'},
          ],
          'reference_rows': <Map<String, Object?>>[
            <String, Object?>{
              'id': 'rr-here',
              'dataset_id': 'ds',
              'key_value': 'K1',
              'values': '{"name":"Here"}',
            },
          ],
        },
      );
      expect(result.inserts['reference_rows']!.single['key_value'], 'K2');
      expect(result.counts.kept, 1);
    });
  });
}

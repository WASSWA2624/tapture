import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/quality/quality.dart';

void main() {
  Map<String, Object?> record(
    String id, {
    String template = 't1',
    Map<String, String> context = const <String, String>{'site': 'Gulu'},
    int capturedAt = 1790000000,
  }) => <String, Object?>{
    'id': id,
    'template_id': template,
    'context_json': jsonEncode(context),
    'captured_at': capturedAt,
  };

  Map<String, Object?> value(String recordId, String key, String text) =>
      <String, Object?>{
        'id': '$recordId-$key',
        'record_id': recordId,
        'field_key': key,
        'value_raw': text,
      };

  Map<String, Object?> caption(String recordId, String text) =>
      <String, Object?>{
        'id': 'c-$recordId',
        'owner_type': 'record',
        'owner_id': recordId,
        'text_raw': text,
      };

  Map<String, Object?> photo(String recordId, String sha) => <String, Object?>{
    'id': 'p-$recordId-$sha',
    'record_id': recordId,
    'sha256': sha,
  };

  final List<Map<String, Object?>> templates = <Map<String, Object?>>[
    <String, Object?>{
      'id': 't1',
      'identity_fields': jsonEncode(<String>['serial']),
    },
    <String, Object?>{'id': 't2', 'identity_fields': '[]'},
  ];

  List<PossibleDuplicate> find(
    Map<String, List<Map<String, Object?>>> incoming,
    Map<String, List<Map<String, Object?>>> local, {
    Iterable<String> candidates = const <String>['in'],
  }) {
    return DuplicateSignals.find(
      incoming: incoming,
      local: <String, List<Map<String, Object?>>>{
        'templates': templates,
        ...local,
      },
      templateMapping: const <String, String>{'t1': 't1', 't2': 't2'},
      candidates: candidates,
    );
  }

  test('equal identity fields pair two records with score 1', () {
    final List<PossibleDuplicate> pairs = find(
      <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[record('in')],
        'record_fields': <Map<String, Object?>>[value('in', 'serial', 'SN-1 ')],
      },
      <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[record('here')],
        'record_fields': <Map<String, Object?>>[
          value('here', 'serial', 'sn-1'),
        ],
      },
    );
    expect(pairs.single.signal, DuplicateSignal.identity);
    expect(pairs.single.localId, 'here');
    expect(pairs.single.score, 1);
  });

  test('differing identity fields are not a pair', () {
    final List<PossibleDuplicate> pairs = find(
      <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[record('in', context: const {})],
        'record_fields': <Map<String, Object?>>[value('in', 'serial', 'SN-1')],
      },
      <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[record('here')],
        'record_fields': <Map<String, Object?>>[
          value('here', 'serial', 'SN-2'),
        ],
      },
    );
    expect(pairs, isEmpty);
  });

  test('an identical photo pairs two records', () {
    final List<PossibleDuplicate> pairs = find(
      <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[record('in', template: 't2')],
        'photos': <Map<String, Object?>>[photo('in', 'sha-1')],
      },
      <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[
          record('here', template: 't2', context: const {}),
        ],
        'photos': <Map<String, Object?>>[photo('here', 'sha-1')],
      },
    );
    expect(pairs.single.signal, DuplicateSignal.photo);
  });

  test('the same context, close in time, with a near-identical caption '
      'pairs two records', () {
    final List<PossibleDuplicate> pairs = find(
      <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[record('in', template: 't2')],
        'captions': <Map<String, Object?>>[
          caption('in', 'Grundfos pump, leaking at the seal'),
        ],
      },
      <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[
          record('here', template: 't2', capturedAt: 1790003600),
        ],
        'captions': <Map<String, Object?>>[
          caption('here', 'Grundfos pump leaking at the seal.'),
        ],
      },
    );
    expect(pairs.single.signal, DuplicateSignal.caption);
    expect(pairs.single.score, greaterThanOrEqualTo(0.9));
  });

  test('a caption match a day and more apart, or elsewhere, is not a pair', () {
    Map<String, List<Map<String, Object?>>> here(
      int capturedAt,
      Map<String, String> context,
    ) => <String, List<Map<String, Object?>>>{
      'records': <Map<String, Object?>>[
        record(
          'here',
          template: 't2',
          capturedAt: capturedAt,
          context: context,
        ),
      ],
      'captions': <Map<String, Object?>>[caption('here', 'Pump leaking')],
    };
    final Map<String, List<Map<String, Object?>>> incoming =
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('in', template: 't2')],
          'captions': <Map<String, Object?>>[caption('in', 'Pump leaking')],
        };
    expect(
      find(incoming, here(1790000000 + 90000, const {'site': 'Gulu'})),
      isEmpty,
    );
    expect(find(incoming, here(1790000000, const {'site': 'Lira'})), isEmpty);
  });

  test('records under different templates are never compared', () {
    final List<PossibleDuplicate> pairs = find(
      <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[record('in', template: 't2')],
        'photos': <Map<String, Object?>>[photo('in', 'sha-1')],
      },
      <String, List<Map<String, Object?>>>{
        'records': <Map<String, Object?>>[record('here')],
        'photos': <Map<String, Object?>>[photo('here', 'sha-1')],
      },
    );
    expect(pairs, isEmpty);
  });

  test('only incoming candidates are compared, and only with live local '
      'records', () {
    final Map<String, List<Map<String, Object?>>> incoming =
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('in'), record('in-2')],
          'record_fields': <Map<String, Object?>>[
            value('in', 'serial', 'SN-1'),
            value('in-2', 'serial', 'SN-1'),
          ],
        };
    final Map<String, List<Map<String, Object?>>> local =
        <String, List<Map<String, Object?>>>{
          'records': <Map<String, Object?>>[record('here'), record('gone')],
          'record_fields': <Map<String, Object?>>[
            value('here', 'serial', 'SN-1'),
            value('gone', 'serial', 'SN-1'),
          ],
          'tombstones': <Map<String, Object?>>[
            <String, Object?>{'entity_type': 'records', 'entity_id': 'gone'},
          ],
        };
    final List<PossibleDuplicate> pairs = find(incoming, local);
    expect(pairs.single.incomingId, 'in');
    expect(pairs.single.localId, 'here');
    expect(find(incoming, local, candidates: const <String>[]), isEmpty);
  });
}

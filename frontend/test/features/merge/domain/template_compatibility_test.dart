import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/domain.dart';

void main() {
  Map<String, Object?> template(String id, {String key = 'pump', int v = 1}) =>
      <String, Object?>{
        'id': id,
        'name': 'Pump check',
        'version': v,
        'detection': jsonEncode(<String, Object?>{'template_key': key}),
      };

  Map<String, Object?> field(
    String template,
    String key, {
    String type = 'text',
    String? label,
    bool required = false,
  }) => <String, Object?>{
    'id': '$template-$key',
    'template_id': template,
    'field_key': key,
    'label': label ?? key,
    'type': type,
    'required': required ? 1 : 0,
    'options': '[]',
  };

  /// One incoming record under [templateId], filling [filled].
  Map<String, List<Map<String, Object?>>> incoming(
    List<Map<String, Object?>> templates,
    List<Map<String, Object?>> fields, {
    String templateId = 'there',
    Map<String, String> filled = const <String, String>{'serial': 'SN-1'},
  }) => <String, List<Map<String, Object?>>>{
    'templates': templates,
    'template_fields': fields,
    'records': <Map<String, Object?>>[
      <String, Object?>{'id': 'r1', 'template_id': templateId},
    ],
    'record_fields': <Map<String, Object?>>[
      for (final MapEntry<String, String> value in filled.entries)
        <String, Object?>{
          'id': 'v-${value.key}',
          'record_id': 'r1',
          'field_key': value.key,
          'value_raw': value.value,
        },
    ],
  };

  Map<String, List<Map<String, Object?>>> local(
    List<Map<String, Object?>> templates,
    List<Map<String, Object?>> fields,
  ) => <String, List<Map<String, Object?>>>{
    'templates': templates,
    'template_fields': fields,
  };

  List<CompatibilityIssue> issuesOf(CompatibilityReport report) =>
      <CompatibilityIssue>[
        for (final ({CompatibilityIssue issue, String field}) found
            in report.templates.single.issues)
          found.issue,
      ];

  test('an identical template is compatible', () {
    final CompatibilityReport report = TemplateCompatibility.check(
      incoming: incoming(
        <Map<String, Object?>>[template('t1')],
        <Map<String, Object?>>[field('t1', 'serial')],
        templateId: 't1',
      ),
      local: local(
        <Map<String, Object?>>[template('t1')],
        <Map<String, Object?>>[field('t1', 'serial')],
      ),
      sameProject: false,
    );
    expect(report.status, CompatibilityStatus.compatible);
    expect(report.mapping, <String, String>{'t1': 't1'});
  });

  test('a match by key under different ids maps them', () {
    final CompatibilityReport report = TemplateCompatibility.check(
      incoming: incoming(
        <Map<String, Object?>>[template('there')],
        <Map<String, Object?>>[field('there', 'serial')],
      ),
      local: local(
        <Map<String, Object?>>[template('here')],
        <Map<String, Object?>>[field('here', 'serial')],
      ),
      sameProject: false,
    );
    expect(report.status, CompatibilityStatus.compatible);
    expect(report.mapping, <String, String>{'there': 'here'});
  });

  test('of several matches, the one sharing most fields wins, then the '
      'newer version', () {
    final CompatibilityReport report = TemplateCompatibility.check(
      incoming: incoming(
        <Map<String, Object?>>[template('there')],
        <Map<String, Object?>>[
          field('there', 'serial'),
          field('there', 'make'),
        ],
      ),
      local: local(
        <Map<String, Object?>>[
          template('few', v: 3),
          template('most'),
          template('most-newer', v: 2),
        ],
        <Map<String, Object?>>[
          field('few', 'serial'),
          field('most', 'serial'),
          field('most', 'make'),
          field('most-newer', 'serial'),
          field('most-newer', 'make'),
        ],
      ),
      sameProject: false,
    );
    expect(report.mapping['there'], 'most-newer');
  });

  test('a different version is compatible with that difference named', () {
    final CompatibilityReport report = TemplateCompatibility.check(
      incoming: incoming(
        <Map<String, Object?>>[template('there', v: 2)],
        <Map<String, Object?>>[field('there', 'serial')],
      ),
      local: local(
        <Map<String, Object?>>[template('here')],
        <Map<String, Object?>>[field('here', 'serial')],
      ),
      sameProject: false,
    );
    expect(report.status, CompatibilityStatus.compatibleWithDifferences);
    expect(issuesOf(report), <CompatibilityIssue>[
      CompatibilityIssue.otherVersion,
    ]);
    expect(report.canMerge, isTrue);
  });

  test('an extra local field is a difference, not a blocker', () {
    final CompatibilityReport report = TemplateCompatibility.check(
      incoming: incoming(
        <Map<String, Object?>>[template('there')],
        <Map<String, Object?>>[field('there', 'serial')],
      ),
      local: local(
        <Map<String, Object?>>[template('here')],
        <Map<String, Object?>>[
          field('here', 'serial'),
          field('here', 'notes', label: 'Notes'),
        ],
      ),
      sameProject: false,
    );
    expect(report.status, CompatibilityStatus.compatibleWithDifferences);
    expect(report.templates.single.issues.single, (
      issue: CompatibilityIssue.localOnlyFields,
      field: 'Notes',
    ));
  });

  test('a filled field missing here blocks; an unfilled one only warns', () {
    final CompatibilityReport blocked = TemplateCompatibility.check(
      incoming: incoming(
        <Map<String, Object?>>[template('there')],
        <Map<String, Object?>>[
          field('there', 'serial'),
          field('there', 'make'),
        ],
        filled: const <String, String>{'make': 'Grundfos'},
      ),
      local: local(
        <Map<String, Object?>>[template('here')],
        <Map<String, Object?>>[field('here', 'serial')],
      ),
      sameProject: false,
    );
    expect(blocked.status, CompatibilityStatus.incompatible);
    expect(blocked.canMerge, isFalse);
    expect(issuesOf(blocked), contains(CompatibilityIssue.missingField));
    final CompatibilityReport warned = TemplateCompatibility.check(
      incoming: incoming(
        <Map<String, Object?>>[template('there')],
        <Map<String, Object?>>[
          field('there', 'serial'),
          field('there', 'make'),
        ],
      ),
      local: local(
        <Map<String, Object?>>[template('here')],
        <Map<String, Object?>>[field('here', 'serial')],
      ),
      sameProject: false,
    );
    expect(warned.status, CompatibilityStatus.compatibleWithDifferences);
    expect(issuesOf(warned), <CompatibilityIssue>[
      CompatibilityIssue.unfilledMissing,
    ]);
  });

  test('a retyped field is allowed when the local type holds the values, '
      'and blocks when it cannot', () {
    CompatibilityReport retyped(String here, String there) {
      return TemplateCompatibility.check(
        incoming: incoming(
          <Map<String, Object?>>[template('there')],
          <Map<String, Object?>>[field('there', 'serial', type: there)],
        ),
        local: local(
          <Map<String, Object?>>[template('here')],
          <Map<String, Object?>>[field('here', 'serial', type: here)],
        ),
        sameProject: false,
      );
    }

    expect(issuesOf(retyped('long_text', 'number')), <CompatibilityIssue>[
      CompatibilityIssue.changedType,
    ]);
    expect(issuesOf(retyped('decimal', 'number')), <CompatibilityIssue>[
      CompatibilityIssue.changedType,
    ]);
    final CompatibilityReport blocked = retyped('number', 'text');
    expect(issuesOf(blocked), <CompatibilityIssue>[
      CompatibilityIssue.typeCannotHold,
    ]);
    expect(blocked.canMerge, isFalse);
  });

  test('no match blocks another project, and the same project brings the '
      'template along', () {
    Map<String, List<Map<String, Object?>>> tables() => incoming(
      <Map<String, Object?>>[template('there', key: 'meter')],
      <Map<String, Object?>>[field('there', 'serial')],
    );
    final Map<String, List<Map<String, Object?>>> here = local(
      <Map<String, Object?>>[template('here')],
      <Map<String, Object?>>[field('here', 'serial')],
    );
    final CompatibilityReport other = TemplateCompatibility.check(
      incoming: tables(),
      local: here,
      sameProject: false,
    );
    expect(issuesOf(other), <CompatibilityIssue>[CompatibilityIssue.noMatch]);
    expect(other.status, CompatibilityStatus.incompatible);
    final CompatibilityReport same = TemplateCompatibility.check(
      incoming: tables(),
      local: here,
      sameProject: true,
    );
    expect(same.status, CompatibilityStatus.compatible);
    expect(same.mapping, isEmpty);
  });

  test('only templates a record uses are reported', () {
    final CompatibilityReport report = TemplateCompatibility.check(
      incoming: incoming(
        <Map<String, Object?>>[template('there'), template('unused')],
        <Map<String, Object?>>[field('there', 'serial')],
      ),
      local: local(
        <Map<String, Object?>>[template('here')],
        <Map<String, Object?>>[field('here', 'serial')],
      ),
      sameProject: false,
    );
    expect(report.templates.single.incomingId, 'there');
  });
}

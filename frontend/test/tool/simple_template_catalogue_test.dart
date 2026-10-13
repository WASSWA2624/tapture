@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/dart_executable.dart';

const String _generator = 'tool/build_template_catalogue.dart';
const String _categoryFile = '01_uni_universal_capture_and_records.json';
const List<String> _observationFields = <String>[
  'observation_subject',
  'observed_at',
  'factual_description',
  'verification_status',
  'country',
];

void main() {
  group('simple catalogue generation', () {
    test('emits only selected fields with their existing types', () async {
      final _Generation generated = await _generate(_source());
      _expectSuccess(generated);
      final Map<String, Object?> template = _template(generated.assets);

      expect(template['inherits_groups'], isEmpty);
      expect(_typed(template), <String, String>{
        'observation_subject': 'text',
        'observed_at': 'date_time',
        'factual_description': 'long_text',
        'verification_status': 'choice',
        'country': 'text',
      });
      final Map<String, Object?> status = _fields(template).singleWhere(
        (Map<String, Object?> field) =>
            field['field_key'] == 'verification_status',
      );
      expect(status['options'], isNotEmpty);
      expect(
        _fields(template).map((Map<String, Object?> f) => f['group']),
        everyElement('specific_details'),
      );
    });

    test('renaming a heading preserves its declared stable key', () async {
      final _Generation generated = await _generate(
        _source(title: 'Simple field note'),
      );
      _expectSuccess(generated);
      final Map<String, Object?> template = _template(generated.assets);

      expect(template['title'], 'Simple field note');
      expect(template['template_key'], 'uni_general_observation');
      expect(template['name'], 'templates.uni_general_observation.name');
      expect(template['code'], 'UNI-001');
    });

    test('retains explicitly selected identity fields', () async {
      final _Generation generated = await _generate(
        _source(identity: <String>['observation_subject', 'observed_at']),
      );
      _expectSuccess(generated);

      expect(_template(generated.assets)['identity_fields'], <String>[
        'observation_subject',
        'observed_at',
      ]);
    });

    test(
      'reports every identity that is outside the selected fields',
      () async {
        final _Generation generated = await _generate(
          _source(identity: <String>['missing_identifier', 'missing_date']),
        );

        _expectRejected(generated);
        expect(
          generated.result.stderr,
          contains('identity "missing_identifier" is not a selected field'),
        );
        expect(
          generated.result.stderr,
          contains('identity "missing_date" is not a selected field'),
        );
        final List<String> findings = (generated.result.stderr as String)
            .trim()
            .split('\n');
        expect(findings, hasLength(2));
        expect(findings, everyElement(matches(RegExp(r':\d+: UNI-001 '))));
      },
    );

    test('rejects more than eight resolved atomic columns', () async {
      final _Generation generated = await _generate(
        _source(
          fields: <String>[..._observationFields, 'weights_and_dimensions'],
        ),
      );

      _expectRejected(generated);
      expect(
        generated.result.stderr,
        contains('has 9 fields; keep at most 8 atomic fields'),
      );
      expect(
        generated.result.stderr,
        matches(RegExp(r':\d+: UNI-001 starter')),
      );
    });

    test(
      'inferred money and quantities retain their companion fields',
      () async {
        final _Generation generated = await _generate(
          _source(
            fields: <String>[
              'observation_subject',
              'observed_at',
              'fuel_cost',
              'item_quantity',
            ],
          ),
        );
        _expectSuccess(generated);
        final Map<String, Object?> template = _template(generated.assets);

        expect(_typed(template), <String, String>{
          'observation_subject': 'text',
          'observed_at': 'date_time',
          'fuel_cost': 'currency',
          'fuel_cost_currency': 'text',
          'item_quantity': 'decimal',
          'item_quantity_unit': 'text',
        });
        expect(
          _fields(template).singleWhere(
            (Map<String, Object?> field) =>
                field['field_key'] == 'item_quantity',
          )['unit'],
          'as_declared',
        );
      },
    );

    for (final ({
          String pack,
          String identifier,
          String value,
          String companion,
          String type,
        })
        fixture
        in <
          ({
            String pack,
            String identifier,
            String value,
            String companion,
            String type,
          })
        >[
          (
            pack: 'TRANS',
            identifier: 'transaction_reference',
            value: 'total_amount',
            companion: 'total_currency',
            type: 'currency',
          ),
          (
            pack: 'TRANS',
            identifier: 'transaction_reference',
            value: 'quantity_total',
            companion: 'quantity_unit',
            type: 'decimal',
          ),
          (
            pack: 'MEASURE',
            identifier: 'measurement_type',
            value: 'measured_value',
            companion: 'measurement_unit',
            type: 'decimal',
          ),
        ]) {
      test(
        '${fixture.value} requires its canonical ${fixture.companion}',
        () async {
          final _Generation missing = await _generate(
            _source(
              pack: fixture.pack,
              fields: <String>[fixture.identifier, fixture.value],
              identity: <String>[fixture.identifier],
            ),
          );
          _expectRejected(missing);
          expect(
            missing.result.stderr,
            contains(
              'field "${fixture.value}" needs selected companion "${fixture.companion}"',
            ),
          );
          expect(
            missing.result.stderr,
            matches(RegExp(r':\d+: UNI-001 field')),
          );

          final _Generation valid = await _generate(
            _source(
              pack: fixture.pack,
              fields: <String>[
                fixture.identifier,
                fixture.value,
                fixture.companion,
              ],
              identity: <String>[fixture.identifier],
            ),
          );
          _expectSuccess(valid);
          expect(_typed(_template(valid.assets)), <String, String>{
            fixture.identifier: 'text',
            fixture.value: fixture.type,
            fixture.companion: 'text',
          });
        },
      );
    }

    test(
      'legacy starter declarations still compose shared field groups',
      () async {
        final _Generation generated = await _generate(
          _source(
            fields: <String>['observation_category', 'observed_details'],
            fieldsOnly: false,
          ),
        );
        _expectSuccess(generated);
        final Map<String, Object?> template = _template(generated.assets);

        expect(template['inherits_groups'], <String>[
          'record_admin',
          'location_context',
          'evidence',
          'review',
          'context_uni',
          'pack_obs',
        ]);
        expect(_typed(template).keys, <String>[
          'observation_category',
          'observed_details',
        ]);
      },
    );
  });

  test('shipped starters are small, independent and distinctly identified', () {
    final Map<String, Object?> catalogue = _json(
      'assets/templates/_catalogue.json',
    );
    final List<Map<String, Object?>> templates = <Map<String, Object?>>[
      for (final Map<String, Object?> category in _objects(
        catalogue['categories'],
      ))
        ..._objects(_json(category['asset']! as String)['templates']),
    ];
    expect(templates, isNotEmpty);
    expect(templates.length, lessThanOrEqualTo(250));
    expect(catalogue['template_count'], templates.length);
    final Set<String> codes = <String>{};
    final Set<String> keys = <String>{};
    final Set<String> titles = <String>{};
    for (final Map<String, Object?> template in templates) {
      final String code = template['code']! as String;
      final List<Map<String, Object?>> fields = _fields(template);
      expect(template['inherits_groups'], isEmpty, reason: code);
      expect(fields.length, inInclusiveRange(1, 8), reason: code);
      expect(codes.add(code), isTrue, reason: code);
      expect(
        keys.add(template['template_key']! as String),
        isTrue,
        reason: code,
      );
      expect(titles.add(template['title']! as String), isTrue, reason: code);
      final Set<String> fieldKeys = fields
          .map((Map<String, Object?> field) => field['field_key']! as String)
          .toSet();
      expect(fieldKeys.length, fields.length, reason: code);
      expect(
        fieldKeys,
        containsAll(template['identity_fields']! as List<Object?>),
        reason: code,
      );
    }
    final Map<String, Object?> fallback = templates.singleWhere(
      (Map<String, Object?> template) => template['code'] == 'UNI-001',
    );
    expect(fallback['title'], 'General observation');
    expect(fallback['template_key'], 'uni_general_observation');
    for (final MapEntry<String, String> expected in <String, String>{
      'AGR-007': 'Crop planting',
      'ENE-012': 'Electricity meter reading',
      'SWE-016': 'Software bug report',
      'BNK-014': 'Loan repayment',
    }.entries) {
      expect(
        templates.singleWhere(
          (Map<String, Object?> template) => template['code'] == expected.key,
        )['title'],
        expected.value,
      );
    }
  });
}

String _source({
  List<String> fields = _observationFields,
  List<String> identity = const <String>['observation_subject'],
  String title = 'Field observation',
  String pack = 'OBS',
  bool fieldsOnly = true,
}) =>
    '''
# Fixture catalogue

**1 distinct templates · 1 categories · 1 supergroups · Version 2.0.0**

## Shared archetype packs

**$pack — ${_packTitle(pack)}**

Fields: ${_packFields(pack)}.

# 01 · Fixture foundations

## UNI — Universal capture and records (1 templates)

Shared category context: organization_ref, project_ref.

### UNI-001 — $title

**Type:** ${_packTitle(pack)} · **Shared pack:** $pack.

**Stable key:** uni_general_observation.

${fieldsOnly ? '**Identity fields:** ${identity.join(', ')}.\n\n' : ''}**${fieldsOnly ? 'Fields only' : 'Specific starter fields'}:** ${fields.join(', ')}.

**Capture:** Photos and optional notes.

**AI assistance:** Propose values from evidence.

**Potential outputs:** Observation record.

**Review:** Verify proposed values.

**Default privacy:** Internal · **Rollout:** P0 · Foundation.
''';

String _packTitle(String pack) => switch (pack) {
  'TRANS' => 'Transaction / repeated line items',
  'MEASURE' => 'Measurement / calculation',
  _ => 'Observation / evidence capture',
};

String _packFields(String pack) => switch (pack) {
  'TRANS' => 'transaction_reference, total_amount, quantity_total',
  'MEASURE' => 'measurement_type, measured_value, measurement_unit',
  _ => 'observation_subject, observed_at, factual_description',
};

Future<_Generation> _generate(String source) async {
  final Directory directory = Directory.systemTemp.createTempSync(
    'tapture_simple_catalogue_',
  );
  addTearDown(() => directory.deleteSync(recursive: true));
  final String sourcePath = '${directory.path}/source.md';
  File(sourcePath).writeAsStringSync(source);
  final String assets = '${directory.path}/templates';
  final ProcessResult result = await Process.run(
    dartExecutable(),
    <String>[
      'run',
      '--verbosity=error',
      _generator,
      '--source=$sourcePath',
      '--assets=$assets',
      '--list=${directory.path}/library.md',
    ],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  return _Generation(result, assets);
}

void _expectSuccess(_Generation generated) {
  expect(
    generated.result.exitCode,
    0,
    reason: generated.result.stderr as String,
  );
  expect(generated.result.stderr, isEmpty);
}

void _expectRejected(_Generation generated) {
  expect(generated.result.exitCode, 1);
  expect(generated.result.stdout, contains('nothing written'));
  expect(Directory(generated.assets).existsSync(), isFalse);
}

Map<String, Object?> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

List<Map<String, Object?>> _objects(Object? value) =>
    (value! as List<Object?>).cast<Map<String, Object?>>();

Map<String, Object?> _template(String assets) =>
    _objects(_json('$assets/$_categoryFile')['templates']).single;

List<Map<String, Object?>> _fields(Map<String, Object?> template) =>
    _objects(template['fields']);

Map<String, String> _typed(Map<String, Object?> template) => <String, String>{
  for (final Map<String, Object?> field in _fields(template))
    field['field_key']! as String: field['type']! as String,
};

final class _Generation {
  const _Generation(this.result, this.assets);

  final ProcessResult result;
  final String assets;
}

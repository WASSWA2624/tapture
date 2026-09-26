@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The generator under test, driven as a process the way a person runs it.
const String _generator = 'tool/build_template_catalogue.dart';

/// A three-template catalogue in the planning format.
const String _fixture = 'test/tool/fixtures/catalogue/templates.md';

/// The same catalogue with a category that lists fewer templates than it
/// declares.
const String _brokenFixture = 'test/tool/fixtures/catalogue/broken_count.md';

/// A finding names its file and a 1-based line.
final RegExp _fileAndLine = RegExp(r'^[\w./\\-]+:\d+: \S');

void main() {
  test('the committed catalogue is what the generator builds', () async {
    final _Run run = await _generate(<String>['--check']);

    expect(run.errors, isEmpty);
    expect(run.exitCode, 0);
    expect(run.summary, contains('current'));
  });

  group('a small catalogue', () {
    late Directory out;
    late String assets;
    late String list;

    setUp(() async {
      out = Directory.systemTemp.createTempSync('tapture_catalogue_');
      assets = '${out.path}/catalogue';
      list = '${out.path}/list.md';
      final _Run run = await _generate(<String>[
        '--source=$_fixture',
        '--assets=$assets',
        '--list=$list',
      ]);
      expect(run.errors, isEmpty);
      expect(run.exitCode, 0);
    });

    tearDown(() => out.deleteSync(recursive: true));

    test('writes an index, the groups and one file per category', () {
      final Map<String, Object?> index = _json('$assets/_catalogue.json');
      expect(index['template_count'], 3);
      expect(index['catalogue_version'], '0.1.0');
      expect(index['categories'], hasLength(2));
      expect(index['packs'], hasLength(3));
      expect(
        Directory(
          assets,
        ).listSync().map((FileSystemEntity file) => file.uri.pathSegments.last),
        unorderedEquals(<String>[
          '_catalogue.json',
          '_groups.json',
          '01_uni_universal_capture_and_records.json',
          '01_fin_finance_accounting_and_expenses.json',
        ]),
      );
      final Map<String, Object?> groups = _json('$assets/_groups.json');
      expect(
        groups.keys,
        containsAll(<String>[
          'context_uni',
          'context_fin',
          'pack_obs',
          'pack_log',
          'pack_trans',
        ]),
      );
      final List<Map<String, Object?>> context = _fields(groups['context_uni']);
      expect(
        context.every((Map<String, Object?> field) {
          return field['stickable'] == true && field['group'] == 'context';
        }),
        isTrue,
      );
    });

    test('types each starter field and keeps columns atomic', () {
      final List<Map<String, Object?>> templates = _templates(
        '$assets/01_uni_universal_capture_and_records.json',
      );
      final Map<String, Object?> observation = templates.first;
      expect(observation['template_key'], 'uni_general_observation');
      expect(observation['title'], 'General observation');
      expect(observation['code'], 'UNI-001');
      expect(observation['kind'], 'observation');
      expect(observation['name'], 'templates.uni_general_observation.name');
      expect(observation['identity_fields'], <String>[
        'observation_subject',
        'observed_at',
      ]);
      expect(observation['inherits_groups'], <String>[
        'record_admin',
        'location_context',
        'evidence',
        'review',
        'context_uni',
        'pack_obs',
      ]);
      expect(_typed(observation), <String, String>{
        'observation_category': 'text',
        'observed_details': 'long_text',
        'approval_at': 'date_time',
      });

      final Map<String, Object?> shift = templates.last;
      expect(_typed(shift), <String, String>{
        'shift_name': 'text',
        'head_count': 'number',
        'fuel_cost': 'currency',
        'fuel_cost_currency': 'text',
      });

      final Map<String, Object?> invoice = _templates(
        '$assets/01_fin_finance_accounting_and_expenses.json',
      ).single;
      expect(_typed(invoice), <String, String>{
        'invoice_number': 'text',
        'supplier_name': 'text',
        'invoice_date': 'date',
        'gross_weight_kg': 'decimal',
        'length_mm': 'decimal',
        'width_mm': 'decimal',
        'height_mm': 'decimal',
      });
      expect(invoice['privacy'], 'restricted');
      expect(invoice['rollout'], 'p2');
    });

    test('the output passes the template checker', () async {
      final Directory root = Directory('${out.path}/templates')..createSync();
      File(
        'assets/templates/_schema.json',
      ).copySync('${root.path}/_schema.json');
      File(
        'assets/templates/_groups.json',
      ).copySync('${root.path}/_groups.json');
      Directory(assets).renameSync('${root.path}/catalogue');

      final ProcessResult result = await Process.run(
        _dartExecutable(),
        <String>['run', 'tool/check_templates.dart', root.path],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(result.stdout, contains('3 asset(s), all atomic'));
    });

    test('lists every template in the readable list', () {
      final String text = File(list).readAsStringSync();
      expect(text, contains('Do not edit by hand'));
      for (final String code in <String>['UNI-001', 'UNI-002', 'FIN-001']) {
        expect(text, contains('| $code |'));
      }
      expect(text, contains('`uni_shift_log`'));
      expect(text, contains('### OBS — Observation / evidence capture'));
    });

    test('check mode names a file that drifted', () async {
      final _Run current = await _generate(<String>[
        '--check',
        '--source=$_fixture',
        '--assets=$assets',
        '--list=$list',
      ]);
      expect(current.exitCode, 0);

      File(list).writeAsStringSync('edited by hand\n');
      final _Run stale = await _generate(<String>[
        '--check',
        '--source=$_fixture',
        '--assets=$assets',
        '--list=$list',
      ]);
      expect(stale.exitCode, 1);
      expect(stale.errors, contains(contains('list.md')));
      expect(stale.errors, contains(contains('out of date')));
    });
  });

  test(
    'a category that lists fewer templates than it declares fails',
    () async {
      final Directory out = Directory.systemTemp.createTempSync('tapture_bad_');
      addTearDown(() => out.deleteSync(recursive: true));
      final _Run run = await _generate(<String>[
        '--source=$_brokenFixture',
        '--assets=${out.path}/catalogue',
        '--list=${out.path}/list.md',
      ]);

      expect(run.exitCode, 1);
      expect(run.errors, contains(contains('FIN declares 2 templates')));
      for (final String error in run.errors) {
        expect(error, matches(_fileAndLine));
      }
      expect(Directory('${out.path}/catalogue').existsSync(), isFalse);
      expect(run.summary, contains('nothing written'));
    },
  );

  test('an argument it does not understand exits 1', () async {
    final _Run run = await _generate(<String>['--bogus']);

    expect(run.exitCode, 1);
    expect(run.errors, contains(contains('unrecognised argument')));
  });
}

Map<String, Object?> _json(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
}

List<Map<String, Object?>> _templates(String path) {
  return _fields(_json(path)['templates']);
}

List<Map<String, Object?>> _fields(Object? value) {
  if (value is Map) {
    return _fields(value['fields']);
  }
  return <Map<String, Object?>>[
    for (final Object? item in value! as List<Object?>)
      item! as Map<String, Object?>,
  ];
}

/// A template's own fields as key to type, in order.
Map<String, String> _typed(Map<String, Object?> template) {
  return <String, String>{
    for (final Map<String, Object?> field in _fields(template['fields']))
      field['field_key']! as String: field['type']! as String,
  };
}

Future<_Run> _generate(List<String> args) async {
  final ProcessResult result = await Process.run(
    _dartExecutable(),
    <String>['run', _generator, ...args],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final Object? errors = result.stderr;
  final Object? output = result.stdout;
  return _Run(result.exitCode, <String>[
    for (final String line in (errors is String ? errors : '').split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ], (output is String ? output : '').trim());
}

String _dartExecutable() {
  final String suffix = Platform.isWindows ? '.exe' : '';
  final String running = Platform.resolvedExecutable;
  if (Uri.file(running).pathSegments.last == 'dart$suffix') {
    return running;
  }
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  return flutterRoot == null
      ? 'dart$suffix'
      : '$flutterRoot/bin/cache/dart-sdk/bin/dart$suffix';
}

class _Run {
  const _Run(this.exitCode, this.errors, this.summary);

  final int exitCode;
  final List<String> errors;
  final String summary;
}

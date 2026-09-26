@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The checker under test, driven as a process.
///
/// Its contract is one function — `Future<int> main(List<String> args)` —
/// so these tests run the script the way `verify.dart` does.
const String _checker = 'tool/check_templates.dart';

/// Shipped assets the default scan walks.
const String _shipped = 'assets/templates';

/// One valid asset and one deliberately broken asset per rule.
const String _fixtures = 'test/tool/fixtures/templates';

/// A finding names its file and a 1-based line.
final RegExp _fileAndLine = RegExp(r'^[\w./\\-]+:\d+: \S');

void main() {
  group('the shipped assets', () {
    test('pass the checker', () async {
      final _Run run = await _check(<String>[_shipped]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
      expect(run.summary, contains('all atomic'));
    });

    test('are what the checker reads when it is given no argument', () async {
      final _Run implicit = await _check(<String>[]);
      final _Run explicit = await _check(<String>[_shipped]);

      expect(implicit.summary, explicit.summary);
      expect(implicit.exitCode, 0);
    });
  });

  group('the catalogue folder', () {
    test('every catalogue template is checked and counted', () async {
      final _Run run = await _check(<String>[_shipped]);

      expect(run.summary, contains('2372 asset(s)'));
    });

    test('a broken catalogue template is named at its own line', () async {
      final Directory dir = Directory.systemTemp.createTempSync('tapture_cat_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final Directory catalogue = Directory('${dir.path}/catalogue')
        ..createSync();
      const JsonEncoder json = JsonEncoder.withIndent('  ');
      File('${catalogue.path}/_groups.json').writeAsStringSync(
        json.convert(<String, Object?>{
          'pack_fixture': <String, Object?>{
            'input_mode': 'any',
            'fields': <Object?>[
              _catalogueField('fixture_reference', 'text'),
              _catalogueField('fixture_cost', 'currency'),
            ],
          },
        }),
      );
      final String category = json.convert(<String, Object?>{
        'category': 'FIX',
        'templates': <Object?>[
          _catalogueTemplate('fix_first', <Object?>[
            _catalogueField('first_note', 'long_text'),
          ], 'pack_fixture'),
          _catalogueTemplate('fix_second', <Object?>[
            _catalogueField('second_note', 'long_text'),
            _catalogueField('service_window', 'date'),
          ], 'pack_missing'),
        ],
      });
      File('${catalogue.path}/01_fix.json').writeAsStringSync(category);
      final List<String> lines = category.split('\n');
      final int window =
          lines.indexWhere((String line) => line.contains('service_window')) +
          1;

      final _Run run = await _check(<String>[dir.path]);

      expect(run.exitCode, 1);
      expect(
        run.violations,
        contains(allOf(contains('01_fix.json:$window:'), contains('_date'))),
      );
      expect(run.violations, contains(contains('"pack_missing"')));
      expect(
        run.violations,
        contains(
          allOf(contains('_groups.json:'), contains('fixture_cost_currency')),
        ),
      );
      expect(run.violations, isNot(contains(contains('first_note'))));
      for (final String violation in run.violations) {
        expect(violation, matches(_fileAndLine));
      }
    });
  });

  group('a valid fixture', () {
    test('exits 0 and reports no violation', () async {
      final _Run run = await _checkFixture('valid.json');

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });
  });

  group('one deliberately broken fixture per rule', () {
    test(
      'a field_key that is not snake_case fails with file and line',
      () async {
        final _Run run = await _checkFixture('broken_snake_case.json');

        expect(run.exitCode, 1);
        expect(run.violations, contains(contains('SerialNumber')));
        expect(run.violations, contains(contains('snake_case')));
        _expectFileAndLine(run, 'broken_snake_case.json');
      },
    );

    test('a duplicated field_key fails with file and line', () async {
      final _Run run = await _checkFixture('broken_duplicate_key.json');

      expect(run.exitCode, 1);
      expect(run.violations, contains(contains('not unique')));
      _expectFileAndLine(run, 'broken_duplicate_key.json');
    });

    test('make_model fails with file and line', () async {
      final _Run run = await _checkFixture('broken_make_model.json');

      expect(run.exitCode, 1);
      expect(run.violations, contains(contains('make_model')));
      expect(run.violations, contains(contains('two facts')));
      _expectFileAndLine(run, 'broken_make_model.json');
    });

    test('address fails with file and line', () async {
      final _Run run = await _checkFixture('broken_address.json');

      expect(run.exitCode, 1);
      expect(run.violations, contains(contains('address')));
      expect(run.violations, contains(contains('two facts')));
      _expectFileAndLine(run, 'broken_address.json');
    });

    test('a packed label or _and_ key fails with file and line', () async {
      final _Run run = await _checkFixture('broken_packed_label.json');

      expect(run.exitCode, 1);
      expect(run.violations, contains(contains('district_and_village')));
      _expectFileAndLine(run, 'broken_packed_label.json');
    });

    test('a measured field without a unit fails with file and line', () async {
      final _Run run = await _checkFixture('broken_measured.json');

      expect(run.exitCode, 1);
      expect(run.violations, contains(contains('width')));
      expect(run.violations, contains(contains('unit')));
      _expectFileAndLine(run, 'broken_measured.json');
    });

    test(
      'cost without a currency companion fails with file and line',
      () async {
        final _Run run = await _checkFixture('broken_cost.json');

        expect(run.exitCode, 1);
        expect(run.violations, contains(contains('cost')));
        expect(run.violations, contains(contains('currency')));
        _expectFileAndLine(run, 'broken_cost.json');
      },
    );

    test(
      'caption_refined without caption_raw fails with file and line',
      () async {
        final _Run run = await _checkFixture('broken_refined.json');

        expect(run.exitCode, 1);
        expect(run.violations, contains(contains('caption_refined')));
        expect(run.violations, contains(contains('caption_raw')));
        _expectFileAndLine(run, 'broken_refined.json');
      },
    );

    test('a lookup *_code without *_name fails with file and line', () async {
      final _Run run = await _checkFixture('broken_code.json');

      expect(run.exitCode, 1);
      expect(run.violations, contains(contains('supplier_code')));
      expect(run.violations, contains(contains('supplier_name')));
      _expectFileAndLine(run, 'broken_code.json');
    });

    test('a date key that is not one date fails with file and line', () async {
      final _Run run = await _checkFixture('broken_date.json');

      expect(run.exitCode, 1);
      expect(run.violations, contains(contains('service_window')));
      expect(run.violations, contains(contains('_date')));
      _expectFileAndLine(run, 'broken_date.json');
    });

    test('a boolean that is not a question fails with file and line', () async {
      final _Run run = await _checkFixture('broken_boolean.json');

      expect(run.exitCode, 1);
      expect(run.violations, contains(contains('fault')));
      expect(run.violations, contains(contains('boolean')));
      _expectFileAndLine(run, 'broken_boolean.json');
    });

    test(
      'identity_fields naming a missing key fails with file and line',
      () async {
        final _Run run = await _checkFixture('broken_identity.json');

        expect(run.exitCode, 1);
        expect(run.violations, contains(contains('missing_key')));
        expect(run.violations, contains(contains('identity_fields')));
        _expectFileAndLine(run, 'broken_identity.json');
      },
    );

    test(
      'required_when naming a missing field fails with file and line',
      () async {
        final _Run run = await _checkFixture('broken_required_when.json');

        expect(run.exitCode, 1);
        expect(run.violations, contains(contains('unknown_field')));
        expect(run.violations, contains(contains('required_when')));
        _expectFileAndLine(run, 'broken_required_when.json');
      },
    );

    test('an unknown type fails with file and line', () async {
      final _Run run = await _checkFixture('broken_unknown_type.json');

      expect(run.exitCode, 1);
      expect(run.violations, contains(contains('widget')));
      expect(run.violations, contains(contains('registry')));
      _expectFileAndLine(run, 'broken_unknown_type.json');
    });
  });

  group('reporting', () {
    test('every broken fixture is named, not only the first', () async {
      final Directory dir = _copyAllBroken();
      final _Run run = await _check(<String>[dir.path]);

      expect(run.exitCode, 1);
      expect(run.violations.length, greaterThan(1));
      expect(run.violations.join('\n'), contains('make_model'));
      expect(run.violations.join('\n'), contains('caption_refined'));
      expect(run.violations.join('\n'), contains('cost'));
    });

    test('every finding names the file and the line', () async {
      final Directory dir = _copyAllBroken();
      final _Run run = await _check(<String>[dir.path]);

      expect(run.violations, isNotEmpty);
      for (final String violation in run.violations) {
        expect(violation, matches(_fileAndLine));
      }
    });

    test(
      'a directory that is not there is said so rather than passing',
      () async {
        final _Run run = await _check(<String>['no_such_templates']);

        expect(
          run.violations,
          contains(contains('there is no directory here to check')),
        );
        expect(run.exitCode, 1);
      },
    );

    test('an argument it does not understand exits 1', () async {
      final _Run run = await _check(<String>['--bogus']);

      expect(run.exitCode, 1);
      expect(run.violations, contains(contains('unrecognised argument')));
      expect(run.violations, contains(contains(_checker)));
    });
  });
}

/// One catalogue field with the keys every field must carry.
Map<String, Object?> _catalogueField(String key, String type) {
  return <String, Object?>{
    'field_key': key,
    'label': 'templates.catalogue.$key',
    'type': type,
    'required': 'OPTIONAL',
  };
}

/// One catalogue template inheriting [pack] beside nothing else.
Map<String, Object?> _catalogueTemplate(
  String key,
  List<Object?> fields,
  String pack,
) {
  return <String, Object?>{
    'schema_version': 1,
    'template_key': key,
    'name': 'templates.$key.name',
    'kind': 'fixture',
    'identity_fields': <String>[],
    'inherits_groups': <String>[pack],
    'fields': fields,
    'child_rows': <Object?>[],
  };
}

/// Copies [name] into a throwaway folder so the scan sees only that asset.
Future<_Run> _checkFixture(String name) async {
  final Directory dir = Directory.systemTemp.createTempSync('tapture_tpl_');
  addTearDown(() => dir.deleteSync(recursive: true));
  File('$_fixtures/$name').copySync('${dir.path}/$name');
  return _check(<String>[dir.path]);
}

/// Every broken fixture in one folder, so a run must list them all.
Directory _copyAllBroken() {
  final Directory dir = Directory.systemTemp.createTempSync('tapture_tpls_');
  addTearDown(() => dir.deleteSync(recursive: true));
  for (final File file in Directory(_fixtures).listSync().whereType<File>()) {
    final String name = file.uri.pathSegments.last;
    if (!name.startsWith('broken_')) {
      continue;
    }
    file.copySync('${dir.path}/$name');
  }
  return dir;
}

void _expectFileAndLine(_Run run, String name) {
  expect(
    run.violations,
    contains(matches(RegExp('${RegExp.escape(name)}:\\d+:'))),
  );
}

Future<_Run> _check(List<String> args) async {
  final ProcessResult result = await Process.run(
    _dartExecutable(),
    <String>['run', _checker, ...args],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final Object? errors = result.stderr;
  final Object? output = result.stdout;
  final List<String> violations = <String>[
    for (final String line in (errors is String ? errors : '').split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
  return _Run(
    result.exitCode,
    violations,
    (output is String ? output : '').trim(),
  );
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
  const _Run(this.exitCode, this.violations, this.summary);

  final int exitCode;
  final List<String> violations;
  final String summary;
}

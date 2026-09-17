@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The checker under test, driven as a process.
const String _checker = 'tool/check_secrets.dart';

/// One fixture per named pattern. Values are fake; reports must not repeat them.
const Map<String, ({String path, String body, String value})>
_fixtures = <String, ({String path, String body, String value})>{
  'provider_key': (
    path: 'lib/keys.dart',
    body: "const String compiled = 'sk-aaaabbbbccccddddeeeeffff';\n",
    value: 'sk-aaaabbbbccccddddeeeeffff',
  ),
  'bearer_token': (
    path: 'lib/auth.dart',
    body: "const String header = 'Bearer aaaaaaaabbbbbbbbcccccccc';\n",
    value: 'Bearer aaaaaaaabbbbbbbbcccccccc',
  ),
  'private_key': (
    path: 'lib/pem.dart',
    body: "const String pem = '-----BEGIN PRIVATE KEY-----';\n",
    value: '-----BEGIN PRIVATE KEY-----',
  ),
  'connection_string': (
    path: 'lib/db.dart',
    body: "const String url = 'postgres://admin:s3cret@localhost/app';\n",
    value: 'postgres://admin:s3cret@localhost/app',
  ),
  'long_base64': (
    path: 'lib/blob.dart',
    body:
        "const String blob = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/ABCDABCDABCDABCD';\n",
    value:
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/ABCDABCDABCDABCD',
  ),
};

void main() {
  group('the shipped tree', () {
    test('holds no compiled-in key', () async {
      final _Run run = await _check(<String>[]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
      expect(run.summary, contains('no compiled-in keys'));
    });

    test(
      'a directory that is not there is said so rather than passing',
      () async {
        final _Run run = await _check(<String>['no_such_directory']);

        expect(
          run.violations,
          contains(contains('there is no directory here to check')),
        );
        expect(run.exitCode, 1);
      },
    );
  });

  group('each named pattern', () {
    for (final MapEntry<String, ({String path, String body, String value})>
        fixture
        in _fixtures.entries) {
      test(
        '${fixture.key} fails, naming the pattern and not the value',
        () async {
          final _Run run = await _check(<String>[
            _project(<String, String>{
              fixture.value.path: fixture.value.body,
            }).path,
          ]);

          expect(
            run.violations,
            contains(contains('${fixture.value.path}:1:')),
          );
          expect(run.violations, contains(contains(fixture.key)));
          expect(
            run.violations.join('\n'),
            isNot(contains(fixture.value.value)),
          );
          expect(run.summary, isNot(contains(fixture.value.value)));
          expect(run.exitCode, 1);
        },
      );
    }
  });

  group('where a key may be pasted', () {
    const String key = 'sk-aaaabbbbccccddddeeeeffff';

    test('a Dart file fails', () async {
      final _Run run = await _check(<String>[
        _project(<String, String>{
          'lib/app.dart': "const String k = '$key';\n",
        }).path,
      ]);

      expect(run.violations, contains(contains('lib/app.dart:1:')));
      expect(run.violations, contains(contains('provider_key')));
    });

    test('a Gradle file fails', () async {
      final _Run run = await _check(<String>[
        _project(<String, String>{
          'android/app/build.gradle.kts': 'apiKey = "$key"\n',
        }).path,
      ]);

      expect(
        run.violations,
        contains(contains('android/app/build.gradle.kts:1:')),
      );
      expect(run.violations, contains(contains('provider_key')));
    });

    test('an asset fails', () async {
      final _Run run = await _check(<String>[
        _project(<String, String>{'assets/config.txt': '$key\n'}).path,
      ]);

      expect(run.violations, contains(contains('assets/config.txt:1:')));
      expect(run.violations, contains(contains('provider_key')));
    });
  });

  group('placeholders', () {
    test('a documented placeholder in a test fixture is allowed', () async {
      final _Run run = await _check(<String>[
        _project(<String, String>{
          'lib/ok.dart': 'const String ok = \'none\';\n',
          'test/fixtures/provider.txt': 'sk-YOURAPIKEYPLACEHOLDER0000\n',
        }).path,
      ]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });

    test('the same placeholder in lib/ fails', () async {
      final _Run run = await _check(<String>[
        _project(<String, String>{
          'lib/keys.dart': "const String k = 'sk-YOURAPIKEYPLACEHOLDER0000';\n",
        }).path,
      ]);

      expect(run.violations, contains(contains('provider_key')));
      expect(run.exitCode, 1);
    });
  });

  group('the pattern file', () {
    test(
      'every pattern is named, so a report can be read without opening it',
      () {
        final String yaml = File(
          'tool/secret_patterns.yaml',
        ).readAsStringSync();
        for (final String name in _fixtures.keys) {
          expect(yaml, contains('$name:'));
          expect(yaml, contains('pattern:'));
        }
      },
    );
  });

  group('reporting', () {
    test('every violation is reported, not only the first', () async {
      final _Run run = await _check(<String>[
        _project(<String, String>{
          'lib/one.dart': _fixtures['provider_key']!.body,
          'lib/two.dart': _fixtures['bearer_token']!.body,
        }).path,
      ]);

      expect(run.violations, hasLength(greaterThanOrEqualTo(2)));
      expect(run.violations, contains(contains('provider_key')));
      expect(run.violations, contains(contains('bearer_token')));
    });

    test('every violation names the file and the line', () async {
      final _Run run = await _check(<String>[
        _project(<String, String>{
          'lib/keys.dart': _fixtures['provider_key']!.body,
        }).path,
      ]);

      expect(run.violations, isNotEmpty);
      for (final String violation in run.violations) {
        expect(violation, matches(RegExp(r'^[\w./-]+:\d+: \S')));
      }
    });
  });
}

/// Writes a throwaway project holding [files] at paths relative to its root.
Directory _project(Map<String, String> files) {
  final Directory root = Directory.systemTemp.createTempSync(
    'tapture_secrets_',
  );
  addTearDown(() => root.deleteSync(recursive: true));
  for (final MapEntry<String, String> file in files.entries) {
    final File written = File('${root.path}/${file.key}');
    written.parent.createSync(recursive: true);
    written.writeAsStringSync(file.value);
  }
  return root;
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

@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The checker under test, driven as a process.
const String _checker = 'tool/check_logging.dart';

/// Identifiers FE-CODE-08 forbids in a log line, and a spelling that contains
/// each one as a whole camel-case word.
const Map<String, String> _banned = <String, String>{
  'key': 'apiKey',
  'secret': 'clientSecret',
  'token': 'accessToken',
  'password': 'password',
  'credential': 'credential',
  'caption': 'caption',
  'transcript': 'transcript',
  'value': 'fieldValue',
};

void main() {
  group('the shipped sources', () {
    test('log nothing they should not', () async {
      final _Run run = await _check(<String>[]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
      expect(run.summary, contains('every call has a level and a tag'));
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

  group('print and debugPrint', () {
    test('print in application code fails with the file and line', () async {
      final _Run run = await _check(<String>[
        _libTree(<String, String>{
          'capture_screen.dart': "void f() {\n  print('hi');\n}\n",
        }).path,
      ]);

      expect(
        run.violations,
        contains(contains('lib/capture_screen.dart:2: print is banned here')),
      );
      expect(run.exitCode, 1);
    });

    test('debugPrint in application code fails', () async {
      final _Run run = await _check(<String>[
        _libTree(<String, String>{
          'capture_screen.dart': "void f() {\n  debugPrint('hi');\n}\n",
        }).path,
      ]);

      expect(run.violations, contains(contains('debugPrint is banned here')));
    });

    test('print under test/ is allowed', () async {
      final _Run run = await _check(<String>[
        _projectTree(<String, String>{
          'test/helper.dart': "void f() {\n  print('hi');\n}\n",
        }).path,
      ]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });

    test('print under tool/ is allowed', () async {
      final _Run run = await _check(<String>[
        _projectTree(<String, String>{
          'tool/helper.dart': "void f() {\n  print('hi');\n}\n",
        }).path,
      ]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });

    test('print in a comment is not a call', () async {
      final _Run run = await _check(<String>[
        _libTree(<String, String>{
          'capture_screen.dart': "// print('hi');\nvoid f() {}\n",
        }).path,
      ]);

      expect(run.violations, isEmpty);
    });
  });

  group('level and tag', () {
    test('a log call missing a tag fails with the file and line', () async {
      final _Run run = await _check(<String>[
        _libTree(<String, String>{
          'capture_screen.dart': "void f() {\n  logger.info('started');\n}\n",
        }).path,
      ]);

      expect(
        run.violations,
        contains(
          contains('lib/capture_screen.dart:2: a log call must pass a tag'),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a log call missing a level fails', () async {
      final _Run run = await _check(<String>[
        _libTree(<String, String>{
          'capture_screen.dart': "void f() {\n  logger.log('io', 'up');\n}\n",
        }).path,
      ]);

      expect(run.violations, contains(contains('must name a level')));
    });

    test('a call with a level and a tag passes', () async {
      final _Run run = await _check(<String>[
        _libTree(<String, String>{
          'capture_screen.dart':
              "void f() {\n  logger.info('capture', 'started');\n}\n",
        }).path,
      ]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });
  });

  group('banned identifiers', () {
    for (final MapEntry<String, String> banned in _banned.entries) {
      test('logging a ${banned.key} identifier fails', () async {
        final _Run run = await _check(<String>[
          _libTree(<String, String>{
            'capture_screen.dart':
                'void f() {\n  logger.info(\'io\', \'x=\$${banned.value}\');\n}\n',
          }).path,
        ]);

        expect(
          run.violations,
          contains(contains('lib/capture_screen.dart:2:')),
        );
        expect(run.violations, contains(contains(banned.value)));
        expect(run.violations, contains(contains(banned.key)));
        expect(run.exitCode, 1);
      });
    }

    test('passing an API key variable as the message fails', () async {
      final _Run run = await _check(<String>[
        _libTree(<String, String>{
          'capture_screen.dart':
              "void f() {\n  logger.info('net', apiKey);\n}\n",
        }).path,
      ]);

      expect(run.violations, contains(contains('apiKey')));
      expect(run.violations, contains(contains('key')));
    });
  });

  group('secret literals in a log line', () {
    test('names the pattern and never prints the value', () async {
      const String key = 'sk-aaaabbbbccccddddeeeeffff';
      final _Run run = await _check(<String>[
        _libTree(<String, String>{
          'capture_screen.dart':
              "void f() {\n  logger.info('net', '$key');\n}\n",
        }).path,
      ]);

      expect(run.violations, contains(contains('provider_key')));
      expect(run.violations, isNot(contains(contains(key))));
      expect(run.summary, isNot(contains(key)));
    });
  });

  group('reporting', () {
    test('every violation is reported, not only the first', () async {
      final _Run run = await _check(<String>[
        _libTree(<String, String>{
          'one.dart': "void f() { print('a'); }\n",
          'two.dart': "void f() { debugPrint('b'); }\n",
        }).path,
      ]);

      expect(run.violations, hasLength(greaterThanOrEqualTo(2)));
      expect(run.summary, contains('2 violation(s)'));
    });

    test('every violation names the file and the line', () async {
      final _Run run = await _check(<String>[
        _libTree(<String, String>{
          'capture_screen.dart': "void f() {\n  print('hi');\n}\n",
        }).path,
      ]);

      expect(run.violations, isNotEmpty);
      for (final String violation in run.violations) {
        expect(violation, matches(RegExp(r'^lib/[\w./-]+\.dart:\d+: \S')));
      }
    });
  });
}

/// Writes a throwaway `lib/` holding [files].
Directory _libTree(Map<String, String> files) {
  final Directory root = Directory.systemTemp.createTempSync(
    'tapture_logging_',
  );
  addTearDown(() => root.deleteSync(recursive: true));
  final Directory sources = Directory('${root.path}/lib')
    ..createSync(recursive: true);
  for (final MapEntry<String, String> file in files.entries) {
    final File written = File('${sources.path}/${file.key}');
    written.parent.createSync(recursive: true);
    written.writeAsStringSync(file.value);
  }
  return sources;
}

/// Writes a throwaway project holding [files] at paths relative to its root.
Directory _projectTree(Map<String, String> files) {
  final Directory root = Directory.systemTemp.createTempSync(
    'tapture_logging_root_',
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

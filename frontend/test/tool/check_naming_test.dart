@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The checker under test, driven as a process.
///
/// Its contract is one function — `Future<int> main(List<String> args)` — so a
/// test that imported something to call would be testing an API the task says
/// must not exist. Running it is also what the build does, which puts the exit
/// code inside what these tests cover rather than behind it.
const String _checker = 'tool/check_naming.dart';

/// The application's own sources, which the checker reads by default and which
/// have to hold to the naming rules.
const String _realSources = 'lib';

/// A project with no `lib/` of its own and one local package whose `lib/`
/// breaks FE-CODE-03 and FE-STR-06 once each.
const String _packageFixture = 'test/tool/fixtures/naming';

/// A file whose name and type agree, used wherever a test needs the tree to be
/// clean apart from the one thing it is breaking.
const String _cleanFile = '''
/// Stands in for a domain model that behaves itself.
class CaptureSession {
  const CaptureSession(this.name);

  final String name;
}
''';

void main() {
  group('the shipped sources', () {
    test('agree with the naming rules', () async {
      final _Run run = await _check(<String>[]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
      expect(run.summary, contains('names and types in agreement'));
    });

    test('are what the checker reads when it is given no argument', () async {
      final _Run implicit = await _check(<String>[]);
      final _Run explicit = await _check(<String>['--project', '.']);

      expect(implicit.summary, explicit.summary);
    });

    test('include lib/ itself', () async {
      final _Run run = await _check(<String>[_realSources]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
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

  group('file names', () {
    test('a snake_case name passes', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{'capture_session.dart': _cleanFile}).path,
      ]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });

    test('a PascalCase name is reported', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{'CaptureSession.dart': _cleanFile}).path,
      ]);

      expect(
        run.violations,
        contains(
          contains(
            'lib/CaptureSession.dart:0: a source file is named in snake_case '
            '(FE-CODE-02), and this one is not',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a camelCase name is reported', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{'captureSession.dart': _cleanFile}).path,
      ]);

      expect(run.violations, contains(contains('captureSession.dart:0:')));
    });

    test('a name joined by hyphens is reported', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{'capture-session.dart': _cleanFile}).path,
      ]);

      expect(run.violations, contains(contains('capture-session.dart:0:')));
    });

    test('a broken file name is reported once, not twice', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{'capture-session.dart': _cleanFile}).path,
      ]);

      expect(run.violations, hasLength(1));
      expect(run.violations.single, contains('named in snake_case'));
    });

    test('generator output is left alone', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'capture_session.dart': _cleanFile,
          'capture_session.g.dart': '''
// GENERATED CODE - DO NOT MODIFY BY HAND

class _\$CaptureSessionImpl {
  const _\$CaptureSessionImpl();
}

class CaptureSessionData {
  const CaptureSessionData();
}
''',
        }).path,
      ]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });
  });

  group('the type a file is named after', () {
    test('a class named for its file passes', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{'capture_session.dart': _cleanFile}).path,
      ]);

      expect(run.violations, isEmpty);
    });

    test('a class renamed without its file is reported', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'capture_session.dart': _cleanFile.replaceAll(
            'CaptureSession',
            'CaptureRun',
          ),
        }).path,
      ]);

      expect(
        run.violations,
        contains(
          contains(
            'lib/capture_session.dart:2: this file is named for CaptureSession '
            'and declares CaptureRun first; a file is named after the type it '
            'holds (FE-STR-06)',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('an enum named for its file passes', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'capture_state.dart': 'enum CaptureState { idle, running }\n',
        }).path,
      ]);

      expect(run.violations, isEmpty);
    });

    test(
      'a mixin, typedef or extension type named for its file passes',
      () async {
        final _Run run = await _check(<String>[
          _tree(<String, String>{
            'capture_clock.dart': 'mixin CaptureClock {}\n',
            'capture_id.dart': 'extension type CaptureId(String value) {}\n',
            'capture_result.dart': 'typedef CaptureResult = String;\n',
          }).path,
        ]);

        expect(run.violations, isEmpty);
      },
    );

    test('a typedef renamed without its file is reported', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'capture_result.dart': 'typedef CaptureOutcome = String;\n',
        }).path,
      ]);

      expect(
        run.violations,
        contains(
          contains(
            'lib/capture_result.dart:1: this file is named for CaptureResult '
            'and declares CaptureOutcome first',
          ),
        ),
      );
    });

    test('a barrel that declares no type passes', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'capture/capture.dart': '''
/// The capture feature: capturing field data.
library;
''',
        }).path,
      ]);

      expect(run.violations, isEmpty);
    });

    test('a file declaring only private types passes', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'main.dart': '''
import 'package:flutter/material.dart';

/// Entry point for the Tapture application.
void main() {
  runApp(const _TaptureApp());
}

class _TaptureApp extends StatelessWidget {
  const _TaptureApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Tapture', home: Scaffold());
  }
}
''',
        }).path,
      ]);

      expect(run.violations, isEmpty);
    });

    test(
      'a class written inside a comment or a string is not a declaration',
      () async {
        final _Run run = await _check(<String>[
          _tree(<String, String>{
            'capture_session.dart': '''
// class CaptureRun {}
/* class CaptureRun {} */
/// Stands in for a domain model that behaves itself.
class CaptureSession {
  const CaptureSession();

  static const String sample = \'\'\'
class CaptureRun {}
\'\'\';
}
''',
          }).path,
        ]);

        expect(run.violations, isEmpty);
        expect(run.exitCode, 0);
      },
    );
  });

  group('one public class per file', () {
    test('a public class beside a private helper passes', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'capture_session.dart': '''
/// Stands in for a domain model that behaves itself.
class CaptureSession {
  const CaptureSession();
}

class _CaptureCursor {
  const _CaptureCursor();
}
''',
        }).path,
      ]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });

    test('a second public class is reported', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'capture_session.dart': '''
/// Stands in for a domain model that behaves itself.
class CaptureSession {
  const CaptureSession();
}

class CaptureCursor {
  const CaptureCursor();
}
''',
        }).path,
      ]);

      expect(
        run.violations,
        contains(
          contains(
            'lib/capture_session.dart:6: CaptureCursor is a second public '
            'class in this file, and a second public class means a second '
            'file (FE-STR-06)',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test(
      'a nested declaration keyword inside a body is not a second class',
      () async {
        final _Run run = await _check(<String>[
          _tree(<String, String>{
            'capture_session.dart': '''
/// Stands in for a domain model that behaves itself.
class CaptureSession {
  const CaptureSession();

  String describe() {
    final String data = 'session';
    return data;
  }
}
''',
          }).path,
        ]);

        expect(run.violations, isEmpty);
      },
    );
  });

  group('provider names', () {
    test('a lowerCamelCase name ending in Provider passes', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'capture_providers.dart': '''
/// Stands in for the providers a feature exposes.
final String captureSessionProvider = 'capture';
''',
        }).path,
      ]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });

    test('a provider named in PascalCase is reported', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'capture_providers.dart': '''
/// Stands in for the providers a feature exposes.
final String CaptureSessionProvider = 'capture';
''',
        }).path,
      ]);

      expect(
        run.violations,
        contains(
          contains(
            'lib/capture_providers.dart:2: CaptureSessionProvider is a '
            'provider, and a provider is named in lowerCamelCase (FE-CODE-02)',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a provider named in snake_case is reported', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'capture_providers.dart': '''
/// Stands in for the providers a feature exposes.
final String capture_session_provider = 'capture';
''',
        }).path,
      ]);

      expect(
        run.violations,
        contains(
          contains(
            'capture_session_provider is a provider, and a provider is named '
            'in lowerCamelCase (FE-CODE-02)',
          ),
        ),
      );
    });

    test('a variable in a providers file that does not end in Provider is '
        'reported', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'capture_providers.dart': '''
/// Stands in for the providers a feature exposes.
final String captureSession = 'capture';
''',
        }).path,
      ]);

      expect(
        run.violations,
        contains(
          contains(
            'lib/capture_providers.dart:2: captureSession sits in a '
            '_providers.dart file, so it is a provider, and a provider ends '
            'in Provider (FE-CODE-02)',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test(
      'a private variable in a providers file is that file\'s own business',
      () async {
        final _Run run = await _check(<String>[
          _tree(<String, String>{
            'capture_providers.dart': '''
/// Stands in for the providers a feature exposes.
const Duration _timeout = Duration(seconds: 3);

final String captureSessionProvider = 'capture';
''',
          }).path,
        ]);

        expect(run.violations, isEmpty);
      },
    );

    test(
      'a name that reads as a provider is checked wherever it is declared',
      () async {
        final _Run run = await _check(<String>[
          _tree(<String, String>{
            'capture_session.dart': '''
/// Stands in for a domain model that behaves itself.
class CaptureSession {
  const CaptureSession();
}

final String capture_provider = 'capture';
''',
          }).path,
        ]);

        expect(
          run.violations,
          contains(
            contains(
              'capture_provider is a provider, and a provider is named in '
              'lowerCamelCase (FE-CODE-02)',
            ),
          ),
        );
      },
    );

    test('an ordinary variable outside a providers file passes', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'capture_session.dart': '''
/// Stands in for a domain model that behaves itself.
class CaptureSession {
  const CaptureSession();
}

const String captureSessionName = 'capture';
''',
        }).path,
      ]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });
  });

  group('banned words', () {
    test('a name built from the domain vocabulary passes', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'reference_dataset.dart': '''
/// Stands in for a type whose name only looks like a banned one.
class ReferenceDataset {
  const ReferenceDataset();
}
''',
        }).path,
      ]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });

    for (final ({String type, String file, String word}) banned
        in <({String type, String file, String word})>[
          (type: 'RecordManager', file: 'record_manager.dart', word: 'manager'),
          (type: 'RecordHelper', file: 'record_helper.dart', word: 'helper'),
          (type: 'RecordUtil', file: 'record_util.dart', word: 'util'),
          (type: 'RecordData', file: 'record_data.dart', word: 'data'),
          (type: 'RecordInfo', file: 'record_info.dart', word: 'info'),
          (type: 'RecordItem', file: 'record_item.dart', word: 'item'),
        ]) {
      test('${banned.type} names the file and the identifier', () async {
        final _Run run = await _check(<String>[
          _tree(<String, String>{
            banned.file: 'class ${banned.type} {}\n',
          }).path,
        ]);

        expect(
          run.violations,
          contains(
            contains(
              'lib/${banned.file}:1: the class ${banned.type} is built out of '
              "the banned word '${banned.word}'",
            ),
          ),
        );
        expect(run.exitCode, 1);
      });
    }

    test('a banned word in the plural is reported', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'record_items.dart': 'class RecordItems {}\n',
        }).path,
      ]);

      expect(run.violations, contains(contains("banned word 'item'")));
    });

    test('a banned word is reported whatever kind of type wears it', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'record_data.dart': 'enum RecordData { one, two }\n',
        }).path,
      ]);

      expect(
        run.violations,
        contains(contains('the enum RecordData is built out of')),
      );
    });

    test('a private type is held to the same vocabulary', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'record_store.dart': '''
/// Stands in for a type whose private neighbour is badly named.
class RecordStore {
  const RecordStore();
}

class _RecordHelper {
  const _RecordHelper();
}
''',
        }).path,
      ]);

      expect(
        run.violations,
        contains(contains('the class _RecordHelper is built out of')),
      );
    });

    test('a type this repository only uses is never reported', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'app_theme.dart': '''
import 'package:flutter/material.dart';

/// Stands in for the shell's theme, which is built out of Flutter's types.
class AppTheme {
  const AppTheme();

  ThemeData light() {
    const IconData glyph = Icons.camera;
    return ThemeData(primaryColor: const Color(0xFF000000), useMaterial3: true);
  }
}

ThemeData darkTheme() => ThemeData.dark();
''',
        }).path,
      ]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });

    test('a member named after a banned word is not a type name', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'capture_session.dart': '''
/// Stands in for a domain model whose fields are not types.
class CaptureSession {
  const CaptureSession(this.data, this.helper);

  final String data;
  final String helper;
}
''',
        }).path,
      ]);

      expect(run.violations, isEmpty);
    });
  });

  group('local packages (dev-plan task 102)', () {
    late _Run run;

    setUpAll(() async {
      run = await _check(<String>['--project', _packageFixture]);
    });

    test('an Info-suffixed type in packages/x/lib is reported', () {
      expect(
        run.violations,
        contains(
          allOf(
            startsWith('packages/x/lib/whisper_model_info.dart:2:'),
            contains("banned word 'info'"),
          ),
        ),
      );
    });

    test('a second public class in packages/x/lib is reported', () {
      expect(
        run.violations,
        contains(
          allOf(
            startsWith('packages/x/lib/whisper_engine.dart:8:'),
            contains('WhisperLoader is a second public class'),
          ),
        ),
      );
    });

    test('a clean package file is not reported, and both are listed', () {
      expect(run.violations, hasLength(2));
      expect(run.violations.join('\n'), isNot(contains('whisper_cell')));
      expect(run.summary, 'naming: 2 violation(s)');
      expect(run.exitCode, 1);
    });
  });

  group('what a report says', () {
    test('every violation is reported, not only the first', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'CaptureSession.dart': _cleanFile,
          'record_data.dart': 'class RecordData {}\n',
          'capture_providers.dart': "final String thing = 'thing';\n",
        }).path,
      ]);

      expect(run.violations, contains(contains('lib/CaptureSession.dart:0:')));
      expect(run.violations, contains(contains('lib/record_data.dart:1:')));
      expect(
        run.violations,
        contains(contains('lib/capture_providers.dart:1:')),
      );
      expect(run.summary, contains('naming: 3 violation(s)'));
      expect(run.exitCode, 1);
    });

    test(
      'every violation names the file and the line that must change',
      () async {
        final _Run run = await _check(<String>[
          _tree(<String, String>{
            'record_data.dart': 'class RecordData {}\n',
            'capture_run.dart': 'class CaptureSession {}\n',
          }).path,
        ]);

        expect(run.violations, isNotEmpty);
        for (final String violation in run.violations) {
          expect(violation, matches(RegExp(r'^lib/[\w./-]+\.dart:\d+: \S')));
        }
      },
    );

    test('one file can break more than one rule at once', () async {
      final _Run run = await _check(<String>[
        _tree(<String, String>{
          'RecordData.dart': 'class RecordData {}\n',
        }).path,
      ]);

      expect(run.violations, hasLength(2));
      expect(run.violations, contains(contains('named in snake_case')));
      expect(run.violations, contains(contains("banned word 'data'")));
    });
  });
}

/// Writes a throwaway `lib/` holding [files], keyed by their path inside it.
Directory _tree(Map<String, String> files) {
  final Directory root = Directory.systemTemp.createTempSync('tapture_naming_');
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

/// Runs the checker with [args] and reads back what it found.
///
/// The output is decoded as UTF-8 rather than as whatever the host's console
/// codepage is: the messages carry em dashes, and on Windows the default
/// decoding turns one into three characters that match nothing.
Future<_Run> _check(List<String> args) async {
  final ProcessResult result = await Process.run(
    _dartExecutable(),
    <String>['run', '--verbosity=error', _checker, ...args],
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

/// The Dart command line, which is not the executable running this test:
/// `flutter test` runs it inside the Flutter tester.
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

/// What one run of the checker produced.
class _Run {
  const _Run(this.exitCode, this.violations, this.summary);

  /// What the process exited with: 0 when every name agrees with the rules.
  final int exitCode;

  /// One line per violation, as the checker wrote them to standard error.
  final List<String> violations;

  /// The one-line summary the checker writes to standard output.
  final String summary;
}

import 'dart:io';

/// The flag that turns a missing-test report into a failure.
const String _strictFlag = '--strict';

/// How to call this, printed when an argument is not one this understands.
const String _usage = 'usage: dart run tool/check_tests.dart [$_strictFlag]';

/// The layers that owe a test, in the order the table prints them.
const List<String> _layers = <String>['domain', 'data', 'widgets', 'screens'];

/// What FE-TEST-02 says each layer's test is.
const Map<String, String> _owedKind = <String, String>{
  'domain': 'a unit test',
  'data': 'an in-memory database test',
  'widgets': 'a behaviour or golden test',
  'screens': 'a widget or integration test',
};

/// Checks that every source file that owes a test has one.
///
/// Takes `--strict`, which exits 1 when a required test is missing — that is
/// the run `verify.dart` calls. Without it the same table is printed and the
/// process exits 0. An optional directory argument is the project root,
/// defaulting to the working directory.
Future<int> main(List<String> args) async {
  final List<String> unknown = args
      .where(
        (String argument) =>
            argument != _strictFlag && argument.startsWith('-'),
      )
      .toList();
  if (unknown.isNotEmpty) {
    stderr.writeln('unrecognised argument(s): ${unknown.join(', ')}');
    stderr.writeln(_usage);
    exitCode = 1;
    return exitCode;
  }
  final bool strict = args.contains(_strictFlag);
  final List<String> rest = args
      .where((String argument) => argument != _strictFlag)
      .toList();
  final Directory root = Directory(
    rest.isEmpty ? Directory.current.path : rest.first,
  );
  final _Report report = _inspect(root);
  _writeTable(report);
  for (final _Finding finding in report.missing) {
    stderr.writeln('${finding.file}:${finding.line}: ${finding.message}');
  }
  stdout.writeln(
    report.missing.isEmpty
        ? 'tests: every owed file has a test'
        : 'tests: ${report.missing.length} missing',
  );
  exitCode = strict && report.missing.isNotEmpty ? 1 : 0;
  return exitCode;
}

/// One source that owes a test and does not have one.
typedef _Finding = ({String file, int line, String message});

/// Counts and findings for one walk of the tree.
typedef _Report = ({
  Map<String, ({int owed, int covered, int missing, int exempt})> layers,
  List<_Finding> missing,
});

/// Reads [root] and reports every owed file that has no test.
_Report _inspect(Directory root) {
  final Map<String, ({int owed, int covered, int missing, int exempt})> layers =
      <String, ({int owed, int covered, int missing, int exempt})>{
        for (final String layer in _layers)
          layer: (owed: 0, covered: 0, missing: 0, exempt: 0),
      };
  if (!root.existsSync()) {
    return (
      layers: layers,
      missing: <_Finding>[
        (
          file: _slash(root.path),
          line: 0,
          message: 'there is no directory here to check',
        ),
      ],
    );
  }
  final Set<String> tests = _testPaths(root);
  final String integration = _integrationSources(root);
  final List<_Finding> missing = <_Finding>[];
  for (final File file in _libSources(root)) {
    final String relative = _relative(root, file);
    final String? layer = _layerOf(relative);
    if (layer == null) {
      continue;
    }
    if (_isExempt(relative, integration)) {
      layers[layer] = _bump(layers[layer]!, exempt: 1);
      continue;
    }
    layers[layer] = _bump(layers[layer]!, owed: 1);
    final String expected = _expectedTest(relative);
    if (_isCovered(relative, expected, tests, integration)) {
      layers[layer] = _bump(layers[layer]!, covered: 1);
      continue;
    }
    layers[layer] = _bump(layers[layer]!, missing: 1);
    missing.add((
      file: relative,
      line: 0,
      message:
          'missing $expected (${_owedKind[layer]}, FE-TEST-01, FE-TEST-02)',
    ));
  }
  return (layers: layers, missing: missing);
}

/// Whether [path] is a barrel, generated, or a screen an integration test
/// already covers.
bool _isExempt(String path, String integration) {
  if (_isGenerated(_basenameFromPath(path))) {
    return true;
  }
  if (_isBarrel(path)) {
    return true;
  }
  if (_isScreen(path) && _integrationCovers(path, integration)) {
    return true;
  }
  return false;
}

/// Whether a test file exists for [path], at [expected] or an allowed stand-in.
bool _isCovered(
  String path,
  String expected,
  Set<String> tests,
  String integration,
) {
  if (tests.contains(expected)) {
    return true;
  }
  final String stem = _stem(_basenameFromPath(path));
  if (path.contains('/core/widgets/') &&
      tests.contains('test/design_system/${stem}_test.dart')) {
    return true;
  }
  if (_isScreen(path) && _integrationCovers(path, integration)) {
    return true;
  }
  return false;
}

/// The test [path] must have, mirroring `lib/` under `test/`.
String _expectedTest(String path) {
  final String underLib = path.startsWith('lib/') ? path.substring(4) : path;
  return 'test/${_stem(underLib)}_test.dart';
}

/// Which owed layer [path] belongs to, or null when it owes nothing.
String? _layerOf(String path) {
  if (path.contains('/domain/')) {
    return 'domain';
  }
  if (path.contains('/data/')) {
    return 'data';
  }
  if (path.contains('/core/widgets/')) {
    return 'widgets';
  }
  if (_isScreen(path)) {
    return 'screens';
  }
  return null;
}

/// A presentation screen file.
bool _isScreen(String path) {
  return path.contains('/presentation/') && path.endsWith('_screen.dart');
}

/// A barrel named after the folder it sits in (FE-STR-08).
bool _isBarrel(String path) {
  final List<String> parts = path.split('/');
  if (parts.length < 2) {
    return false;
  }
  return _stem(parts.last) == parts[parts.length - 2];
}

/// Generator output: a second extension before `.dart`.
bool _isGenerated(String name) {
  return name.endsWith('.dart') && name.split('.').length > 2;
}

/// Whether an integration test names this screen.
bool _integrationCovers(String path, String integration) {
  if (integration.isEmpty) {
    return false;
  }
  final String stem = _stem(_basenameFromPath(path));
  final String type = _pascalCase(stem);
  return integration.contains(type) || integration.contains(stem);
}

/// Prints the per-layer table to standard output.
void _writeTable(_Report report) {
  stdout.writeln(
    '${'layer'.padRight(8)}  ${'owed'.padLeft(4)}  ${'covered'.padLeft(7)}  '
    '${'missing'.padLeft(7)}  ${'exempt'.padLeft(6)}',
  );
  for (final String layer in _layers) {
    final ({int owed, int covered, int missing, int exempt}) row =
        report.layers[layer]!;
    stdout.writeln(
      '${layer.padRight(8)}  ${'${row.owed}'.padLeft(4)}  '
      '${'${row.covered}'.padLeft(7)}  ${'${row.missing}'.padLeft(7)}  '
      '${'${row.exempt}'.padLeft(6)}',
    );
  }
}

/// Adds [owed], [covered], [missing] or [exempt] to [row].
({int owed, int covered, int missing, int exempt}) _bump(
  ({int owed, int covered, int missing, int exempt}) row, {
  int owed = 0,
  int covered = 0,
  int missing = 0,
  int exempt = 0,
}) {
  return (
    owed: row.owed + owed,
    covered: row.covered + covered,
    missing: row.missing + missing,
    exempt: row.exempt + exempt,
  );
}

/// Hand-written Dart sources under `lib/`.
List<File> _libSources(Directory root) {
  final Directory lib = Directory('${root.path}/lib');
  if (!lib.existsSync()) {
    return const <File>[];
  }
  final List<File> sources = <File>[
    for (final FileSystemEntity entity in lib.listSync(recursive: true))
      if (entity is File && _basename(entity.uri).endsWith('.dart')) entity,
  ];
  return sources..sort((File a, File b) => a.path.compareTo(b.path));
}

/// Test files under `test/`, as paths relative to [root].
Set<String> _testPaths(Directory root) {
  final Directory tests = Directory('${root.path}/test');
  if (!tests.existsSync()) {
    return const <String>{};
  }
  return <String>{
    for (final FileSystemEntity entity in tests.listSync(recursive: true))
      if (entity is File && _basename(entity.uri).endsWith('.dart'))
        _relative(root, entity),
  };
}

/// The text of every file under `integration_test/`, so a screen can be
/// matched by name.
String _integrationSources(Directory root) {
  final Directory folder = Directory('${root.path}/integration_test');
  if (!folder.existsSync()) {
    return '';
  }
  final StringBuffer buffer = StringBuffer();
  for (final FileSystemEntity entity in folder.listSync(recursive: true)) {
    if (entity is File && _basename(entity.uri).endsWith('.dart')) {
      buffer.write(entity.readAsStringSync());
      buffer.write('\n');
    }
  }
  return buffer.toString();
}

/// The snake_case [stem] as the type a file of that name holds.
String _pascalCase(String stem) {
  return stem
      .split('_')
      .where((String word) => word.isNotEmpty)
      .map((String word) => word[0].toUpperCase() + word.substring(1))
      .join();
}

String _stem(String name) {
  return name.endsWith('.dart') ? name.substring(0, name.length - 5) : name;
}

String _basenameFromPath(String path) {
  final int slash = path.lastIndexOf('/');
  return slash == -1 ? path : path.substring(slash + 1);
}

String _relative(Directory root, File file) {
  final String from = _slash(root.path);
  final String to = _slash(file.path);
  return to.startsWith('$from/') ? to.substring(from.length + 1) : to;
}

String _slash(String path) => path.replaceAll(r'\', '/');

String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}

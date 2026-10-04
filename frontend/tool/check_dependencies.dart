import 'dart:io';

import 'paths.dart';

/// Where the two files this compares live, relative to the directory checked.
const String _pubspec = 'pubspec.yaml';
const String _allowlist = 'tool/allowlist.yaml';

/// The rule a package that nobody approved has broken.
const String _rule =
    'frontend/.rules/13-workflow.md FE-FLOW-06: adding a package requires its '
    'own task, an allowlist entry with a pinned version, a licence check and a '
    'note on what it replaces';

/// The rule a local package dependency has broken.
const String _localRule =
    'frontend/.rules/01-structure.md FE-STR-01: a local package lives under '
    '$localPackagesRoot/, is a path dependency with a nested version: equal to '
    "the package's own version, has no Dart build hook, and depends only on "
    'approved packages';

/// What a block-declared package with neither `sdk:` nor `version:` reads
/// as. No allowlist entry approves it, so it is reported rather than quietly
/// accepted.
const String _unpinned = 'unpinned';

/// How hard the checker complains. An unapproved package or a version that
/// drifted fails the build; a package that left pubspec.yaml but is still
/// approved does not, because deleting a dependency breaks nothing — it only
/// leaves this file describing something that is no longer there.
enum _Severity { error, warning }

/// One thing wrong, and the file and line that has to change to fix it.
typedef _Violation = ({
  String file,
  int line,
  String message,
  _Severity severity,
});

/// A package as one of the two files declares it: the version it asks for,
/// the line that names it and, for a path dependency, the path and the lines
/// of its `path:` and `version:` keys.
typedef _Entry = ({
  String version,
  int line,
  String? path,
  int pathLine,
  int versionLine,
});

/// Checks pubspec against the allowlist, printing one line per violation.
///
/// Takes the directory to check, defaulting to the working directory. Exits 0
/// when nothing is wrong or only a warning is, and 1 on any error.
Future<int> main(List<String> args) async {
  final Directory root = Directory(
    args.isEmpty ? Directory.current.path : args.first,
  );
  final List<_Violation> violations = _findViolations(root);
  for (final _Violation violation in violations) {
    stderr.writeln(
      '${violation.file}:${violation.line}: ${violation.severity.name}: '
      '${violation.message}',
    );
  }
  final int errors = violations
      .where((_Violation each) => each.severity == _Severity.error)
      .length;
  final int warnings = violations.length - errors;
  stdout.writeln(
    violations.isEmpty
        ? 'dependencies: every direct dependency is approved and pinned'
        : 'dependencies: $errors error(s), $warnings warning(s)',
  );
  exitCode = errors == 0 ? 0 : 1;
  return exitCode;
}

/// Reports every difference between what pubspec asks for and what the
/// allowlist approves: a package nobody approved, a version that drifted, a
/// local package that breaks FE-STR-01, and an approval left behind by a
/// package that has gone.
///
/// Reports all of them, so one run says everything that has to change.
List<_Violation> _findViolations(Directory root) {
  final File pubspec = File('${root.path}/$_pubspec');
  final File allowlist = File('${root.path}/$_allowlist');
  final List<_Violation> violations = <_Violation>[];
  if (!pubspec.existsSync()) {
    violations.add((
      file: _pubspec,
      line: 0,
      message:
          'the project has no $_pubspec, so nothing declares what it depends '
          'on',
      severity: _Severity.error,
    ));
  }
  if (!allowlist.existsSync()) {
    violations.add((
      file: _allowlist,
      line: 0,
      message:
          'the project has no $_allowlist, so every package is unapproved. '
          '$_rule',
      severity: _Severity.error,
    ));
  }
  if (violations.isNotEmpty) {
    return violations;
  }

  final Map<String, _Entry> declared = _readPubspec(pubspec);
  final Map<String, _Entry> approved = _readAllowlist(allowlist);

  violations.addAll(_unapproved(_pubspec, declared, approved));
  final Set<String> localDependencies = <String>{};
  for (final MapEntry<String, _Entry> package in declared.entries) {
    if (package.value.path != null) {
      violations.addAll(
        _localPackageViolations(
          root,
          package.key,
          package.value,
          approved,
          localDependencies,
        ),
      );
    }
  }

  for (final MapEntry<String, _Entry> approval in approved.entries) {
    if (!declared.containsKey(approval.key) &&
        !localDependencies.contains(approval.key)) {
      violations.add((
        file: _allowlist,
        line: approval.value.line,
        message:
            '${approval.key} is approved but $_pubspec no longer asks for it. '
            'Drop the entry so the allowlist keeps describing the project',
        severity: _Severity.warning,
      ));
    }
  }

  return violations;
}

/// Every package [declared] in [file] that the allowlist does not approve at
/// the version it asks for.
List<_Violation> _unapproved(
  String file,
  Map<String, _Entry> declared,
  Map<String, _Entry> approved,
) {
  final List<_Violation> violations = <_Violation>[];
  for (final MapEntry<String, _Entry> package in declared.entries) {
    final _Entry? approval = approved[package.key];
    if (approval == null) {
      violations.add((
        file: file,
        line: package.value.line,
        message:
            '${package.key} is not on the allowlist. Add it to $_allowlist '
            'with a pinned version, a purpose and the task that introduced it, '
            'or take it back out. $_rule',
        severity: _Severity.error,
      ));
    } else if (approval.version != package.value.version) {
      violations.add((
        file: file,
        line: package.value.line,
        message:
            '${package.key} asks for ${package.value.version}; $_allowlist '
            'approves ${approval.version}. A version change is a change of '
            'dependency, so one of the two has to move',
        severity: _Severity.error,
      ));
    }
  }
  return violations;
}

/// The local-package rules for the path dependency [name] (FE-STR-01): it
/// resolves under [localPackagesRoot], carries a nested `version:` equal to
/// the package's own, has no `hook/`, and every dependency the package itself
/// declares is approved at its pin. Those dependencies are added to
/// [localDependencies], so their approvals are not reported as stale.
List<_Violation> _localPackageViolations(
  Directory root,
  String name,
  _Entry entry,
  Map<String, _Entry> approved,
  Set<String> localDependencies,
) {
  final String path = _normalised(entry.path ?? '');
  final List<String> segments = path.split('/');
  if (segments.length < 2 ||
      segments.first != localPackagesRoot ||
      segments.contains('..')) {
    return <_Violation>[
      (
        file: _pubspec,
        line: entry.pathLine,
        message:
            '$name is a path dependency on ${entry.path}, which is not under '
            '$localPackagesRoot/. $_localRule',
        severity: _Severity.error,
      ),
    ];
  }
  final List<_Violation> violations = <_Violation>[];
  final bool pinned = entry.version != _unpinned;
  if (!pinned) {
    violations.add((
      file: _pubspec,
      line: entry.line,
      message:
          '$name is a path dependency with no nested version:. Pin it to the '
          "package's own version. $_localRule",
      severity: _Severity.error,
    ));
  }
  final String packagePubspec = '$path/$_pubspec';
  final File own = File('${root.path}/$packagePubspec');
  if (!own.existsSync()) {
    violations.add((
      file: _pubspec,
      line: entry.pathLine,
      message: '$name points at $path, which holds no $_pubspec. $_localRule',
      severity: _Severity.error,
    ));
    return violations;
  }
  final ({String version, int line}) ownVersion = _ownVersion(own);
  if (pinned && ownVersion.version != entry.version) {
    violations.add((
      file: _pubspec,
      line: entry.versionLine,
      message:
          '$name asks for ${entry.version}; $packagePubspec:'
          '${ownVersion.line} declares ${ownVersion.version}. $_localRule',
      severity: _Severity.error,
    ));
  }
  if (Directory('${root.path}/$path/hook').existsSync()) {
    violations.add((
      file: _pubspec,
      line: entry.line,
      message:
          '$name has a Dart build hook ($path/hook/); a local package builds '
          'through its platform projects only. $_localRule',
      severity: _Severity.error,
    ));
  }
  final Map<String, _Entry> dependencies = _readPubspec(own);
  localDependencies.addAll(dependencies.keys);
  violations.addAll(_unapproved(packagePubspec, dependencies, approved));
  return violations;
}

/// The top-level `version:` of a package's own pubspec, and its line.
({String version, int line}) _ownVersion(File pubspec) {
  final List<String> lines = pubspec.readAsLinesSync();
  for (int index = 0; index < lines.length; index++) {
    final String raw = lines[index];
    if (raw.startsWith('version:')) {
      return (
        version: _unquote(raw.substring('version:'.length).trim()),
        line: index + 1,
      );
    }
  }
  return (version: _unpinned, line: 1);
}

/// [path] with forward slashes, and without empty or `.` segments.
String _normalised(String path) => path
    .replaceAll(r'\', '/')
    .split('/')
    .where((String segment) => segment.isNotEmpty && segment != '.')
    .join('/');

/// Reads the direct dependencies pubspec declares, both runtime and dev, as
/// the version each asks for.
///
/// A transitive package is not read: nothing chooses one directly, so nothing
/// approves one directly either.
Map<String, _Entry> _readPubspec(File file) {
  const List<String> sections = <String>['dependencies', 'dev_dependencies'];
  final Map<String, _Entry> declared = <String, _Entry>{};
  final List<String> lines = file.readAsLinesSync();
  String? section;
  for (int index = 0; index < lines.length; index++) {
    final String raw = lines[index];
    final String trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    final int indent = raw.length - raw.trimLeft().length;
    if (indent == 0) {
      section = trimmed.endsWith(':')
          ? trimmed.substring(0, trimmed.length - 1).trim()
          : null;
      continue;
    }
    if (indent != 2 || !sections.contains(section)) {
      continue;
    }
    final int separator = trimmed.indexOf(':');
    if (separator == -1) {
      continue;
    }
    final String name = trimmed.substring(0, separator).trim();
    final String inline = _unquote(trimmed.substring(separator + 1).trim());
    declared[name] = inline.isNotEmpty
        ? _approval(inline, index + 1)
        : _nested(lines, index);
  }
  return declared;
}

/// A package declared as a block rather than as one scalar: `sdk: flutter`
/// for a package that ships with Flutter, `version:` for a hosted, git or
/// path dependency that pins one, and `path:` for a local package.
///
/// Anything else is left as [_unpinned], which no allowlist entry matches,
/// so it is reported rather than quietly accepted.
_Entry _nested(List<String> lines, int index) {
  String version = _unpinned;
  String? path;
  int pathLine = index + 1;
  int versionLine = index + 1;
  for (int next = index + 1; next < lines.length; next++) {
    final String raw = lines[next];
    final String trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    if (raw.length - raw.trimLeft().length <= 2) {
      break;
    }
    final int separator = trimmed.indexOf(':');
    if (separator == -1) {
      continue;
    }
    final String key = trimmed.substring(0, separator).trim();
    final String value = _unquote(trimmed.substring(separator + 1).trim());
    if (key == 'sdk' && version == _unpinned) {
      version = 'sdk';
    } else if (key == 'version') {
      version = value;
      versionLine = next + 1;
    } else if (key == 'path') {
      path = value;
      pathLine = next + 1;
    }
  }
  return (
    version: version,
    line: index + 1,
    path: path,
    pathLine: pathLine,
    versionLine: versionLine,
  );
}

/// Reads the approved packages and the version each is approved at.
Map<String, _Entry> _readAllowlist(File file) {
  final Map<String, _Entry> approved = <String, _Entry>{};
  final List<String> lines = file.readAsLinesSync();
  bool inPackages = false;
  String? current;
  int currentLine = 0;
  for (int index = 0; index < lines.length; index++) {
    final String raw = lines[index];
    final String trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    final int indent = raw.length - raw.trimLeft().length;
    if (indent == 0) {
      inPackages = trimmed == 'packages:';
      current = null;
      continue;
    }
    if (!inPackages) {
      continue;
    }
    final int separator = trimmed.indexOf(':');
    if (separator == -1) {
      continue;
    }
    final String key = trimmed.substring(0, separator).trim();
    final String value = _unquote(trimmed.substring(separator + 1).trim());
    if (indent == 2) {
      current = key;
      currentLine = index + 1;
      approved[key] = _approval(_unpinned, currentLine);
    } else if (indent == 4 && key == 'version' && current != null) {
      approved[current] = _approval(value, currentLine);
    }
  }
  return approved;
}

/// A package asking for, or approved at, [version], named on [line].
_Entry _approval(String version, int line) => (
  version: version,
  line: line,
  path: null,
  pathLine: line,
  versionLine: line,
);

/// Drops the quotes around a YAML scalar, so a quoted and a bare spelling of
/// the same value compare equal.
String _unquote(String value) {
  if (value.length < 2) {
    return value;
  }
  final String first = value.substring(0, 1);
  final String last = value.substring(value.length - 1);
  final bool quoted = first == last && (first == '"' || first == "'");
  return quoted ? value.substring(1, value.length - 1) : value;
}

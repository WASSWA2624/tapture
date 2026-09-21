import 'dart:io';

/// Where the plan sits relative to `frontend/`, which is where the checkers
/// run from.
///
/// The plan is a sibling of the application, never something it imports
/// (`frontend/.rules/01-structure.md`, FE-STR-01), so this tool reaches out of
/// the package to read it rather than pulling it in.
const String _defaultPlanRoot = '../dev-plan';

/// A task file is `NNN-slug.md`. Anything else in the plan folder — the index,
/// a phase README — describes the plan rather than being a task in it.
final RegExp _taskFileName = RegExp(r'^(\d{3})-(.+)\.md$');

/// The ledger of numbers the plan has given up, which is what turns a hole in
/// the numbering into something stated rather than something lost.
const String _retiredLedger = 'RETIRED.md';

/// The heading the ledger keeps its machine-read table under.
const String _retiredSection = 'Retired numbers';

/// One row of that table: `| 121–281 | why |`, or `| 121 | why |` for one.
final RegExp _retiredRow = RegExp(r'^\|\s*(\d{3})\s*(?:[-–—]\s*(\d{3})\s*)?\|');

/// The number the file claims in its own first heading: `# 003 — Title`.
final RegExp _heading = RegExp(r'^#\s+(\d+)\s');

/// One dependency link out of the `**Depends on**` line: `[003](003-slug.md)`.
final RegExp _dependencyLink = RegExp(r'\[(\d+)\]\(([^)]+)\)');

/// A Definition of done entry, ticked or not.
final RegExp _checkbox = RegExp(r'^- \[[ xX]\]');

/// The sections every task file has to carry.
const List<String> _requiredSections = <String>[
  'Implement',
  'Files',
  'Definition of done',
];

/// One thing wrong with the plan, and the file and line that has to change.
typedef _Violation = ({String file, int line, String message});

/// One task file, read far enough to check it against the others.
typedef _Task = ({
  int number,
  String slug,
  String path,
  File file,
  List<String> lines,
});

/// Checks the plan's own structure, printing one line per violation.
///
/// Takes the plan directory to scan, defaulting to the plan beside this
/// package. Exits 0 when the plan holds together and 1 on any structural
/// error.
Future<int> main(List<String> args) async {
  final Directory root = Directory(
    args.isEmpty ? _defaultPlanRoot : args.first,
  );
  final List<_Task> tasks = _readTasks(root);
  final List<_Violation> violations = _findViolations(root, tasks);
  for (final _Violation violation in violations) {
    stderr.writeln('${violation.file}:${violation.line}: ${violation.message}');
  }
  stdout.writeln(
    violations.isEmpty
        ? 'plan: ${tasks.length} tasks, numbering and links intact'
        : 'plan: ${violations.length} violation(s)',
  );
  exitCode = violations.isEmpty ? 0 : 1;
  return exitCode;
}

/// Reports every way the plan under [root] contradicts itself: a file whose
/// heading disagrees with its name, a number used twice or skipped without
/// being retired, a retired number still in use, a slug used twice, a missing
/// section, a Definition of done nobody can tick, and a dependency that does
/// not resolve or points forward.
///
/// Reports all of them, so one run says everything that has to change.
List<_Violation> _findViolations(Directory root, List<_Task> tasks) {
  if (!root.existsSync()) {
    return <_Violation>[
      (
        file: _displayRoot(root),
        line: 0,
        message: 'there is no plan directory here to check',
      ),
    ];
  }
  if (tasks.isEmpty) {
    return <_Violation>[
      (
        file: _displayRoot(root),
        line: 0,
        message: 'the plan directory holds no NNN-slug.md task file',
      ),
    ];
  }
  return <_Violation>[
    ..._numberingViolations(tasks),
    ..._uniquenessViolations(tasks, _retiredNumbers(root)),
    ..._sectionViolations(tasks),
    ..._definitionOfDoneViolations(tasks),
    ..._dependencyViolations(tasks),
  ];
}

/// Every number the ledger under [root] retires, and none when there is no
/// ledger to read.
///
/// Merging tasks leaves their numbers behind. Reusing one would make the
/// tracker and the commit history point at work that is not there any more, so
/// the plan retires the number instead and says so here.
Set<int> _retiredNumbers(Directory root) {
  final File ledger = File.fromUri(root.uri.resolve(_retiredLedger));
  if (!ledger.existsSync()) {
    return <int>{};
  }
  final List<String> lines = ledger.readAsLinesSync();
  final int start = _lineOfSection(lines, _retiredSection);
  if (start == 0) {
    return <int>{};
  }
  final Set<int> retired = <int>{};
  for (final String line in _sectionBody(lines, start)) {
    final Match? row = _retiredRow.firstMatch(line.trim());
    if (row == null) {
      continue;
    }
    final int first = int.parse(row.group(1)!);
    final int last = int.parse(row.group(2) ?? row.group(1)!);
    for (int number = first; number <= last; number++) {
      retired.add(number);
    }
  }
  return retired;
}

/// Reports a file whose first heading claims a different number than its name,
/// and a file carrying no numbered heading at all.
Iterable<_Violation> _numberingViolations(List<_Task> tasks) sync* {
  for (final _Task task in tasks) {
    final int line = _lineMatching(task.lines, _heading);
    if (line == 0) {
      yield (
        file: task.path,
        line: 1,
        message:
            'no heading of the form `# ${_padded(task.number)} — Title`, so '
            'nothing in the file says which task it is',
      );
      continue;
    }
    final Match match = _heading.firstMatch(task.lines[line - 1])!;
    final int claimed = int.parse(match.group(1)!);
    if (claimed != task.number) {
      yield (
        file: task.path,
        line: line,
        message:
            'the heading says task ${_padded(claimed)} and the filename says '
            '${_padded(task.number)}; renaming a file means renaming its '
            'heading',
      );
    }
  }
}

/// Reports a number or a slug used twice, a number the plan skips without
/// retiring it, and a number [retired] names that a file still carries.
///
/// Contiguity matters because the plan is the backlog (FE-FLOW-08): a gap is
/// either a task somebody deleted without saying so or one that was never
/// written. Saying so in `RETIRED.md` is what makes the third case — a task
/// merged into another — a decision on the record rather than a hole.
Iterable<_Violation> _uniquenessViolations(
  List<_Task> tasks,
  Set<int> retired,
) sync* {
  final Map<int, List<_Task>> byNumber = <int, List<_Task>>{};
  final Map<String, List<_Task>> bySlug = <String, List<_Task>>{};
  for (final _Task task in tasks) {
    byNumber.putIfAbsent(task.number, () => <_Task>[]).add(task);
    bySlug.putIfAbsent(task.slug, () => <_Task>[]).add(task);
  }
  for (final MapEntry<int, List<_Task>> entry in byNumber.entries) {
    if (entry.value.length > 1) {
      for (final _Task task in entry.value.skip(1)) {
        yield (
          file: task.path,
          line: 1,
          message:
              'task ${_padded(entry.key)} is also ${entry.value.first.path}; '
              'a number names one task',
        );
      }
    }
  }
  for (final MapEntry<String, List<_Task>> entry in bySlug.entries) {
    if (entry.value.length > 1) {
      for (final _Task task in entry.value.skip(1)) {
        yield (
          file: task.path,
          line: 1,
          message:
              'the slug ${entry.key} is also ${entry.value.first.path}; a slug '
              'names one task',
        );
      }
    }
  }
  for (final int number in retired.toList()..sort()) {
    final List<_Task>? live = byNumber[number];
    if (live != null) {
      yield (
        file: live.first.path,
        line: 1,
        message:
            'task ${_padded(number)} is retired in $_retiredLedger, so no file '
            'may carry that number again',
      );
    }
  }
  final int highest = byNumber.keys.reduce((int a, int b) => a > b ? a : b);
  for (int number = 1; number <= highest; number++) {
    if (!byNumber.containsKey(number) && !retired.contains(number)) {
      yield (
        file: _parentOf(tasks.first.path),
        line: 0,
        message:
            'the plan runs to ${_padded(highest)} but has no task '
            '${_padded(number)}; the numbering has a hole in it, and '
            '$_retiredLedger does not retire it',
      );
    }
  }
}

/// Reports a task file missing one of the sections every task has to carry.
Iterable<_Violation> _sectionViolations(List<_Task> tasks) sync* {
  for (final _Task task in tasks) {
    for (final String section in _requiredSections) {
      if (_lineOfSection(task.lines, section) == 0) {
        yield (file: task.path, line: 1, message: 'no `## $section` section');
      }
    }
  }
}

/// Reports a Definition of done holding no checkbox, ticked or not.
///
/// A section with nothing to tick cannot be finished on purpose, and
/// FE-FLOW-03 says done means the checklist is ticked.
Iterable<_Violation> _definitionOfDoneViolations(List<_Task> tasks) sync* {
  for (final _Task task in tasks) {
    final int start = _lineOfSection(task.lines, 'Definition of done');
    if (start == 0) {
      continue;
    }
    final bool ticked = _sectionBody(task.lines, start).any(_checkbox.hasMatch);
    if (!ticked) {
      yield (
        file: task.path,
        line: start,
        message:
            'the Definition of done has no checkbox, so nothing about this '
            'task can be ticked off',
      );
    }
  }
}

/// Reports a dependency link that names no file on disk, and one that points
/// at a task numbered the same or higher.
///
/// A plan is worked top to bottom, so a task may only rest on one already
/// finished. A forward link is a cycle waiting to be discovered.
Iterable<_Violation> _dependencyViolations(List<_Task> tasks) sync* {
  final Set<int> known = <int>{for (final _Task task in tasks) task.number};
  for (final _Task task in tasks) {
    final int line = _lineMatching(task.lines, RegExp(r'\*\*Depends on\*\*'));
    if (line == 0) {
      continue;
    }
    for (final Match match in _dependencyLink.allMatches(
      task.lines[line - 1],
    )) {
      final int target = int.parse(match.group(1)!);
      final String link = match.group(2)!;
      if (target >= task.number) {
        yield (
          file: task.path,
          line: line,
          message:
              'depends on task ${_padded(target)}, which is not lower than '
              '${_padded(task.number)}; the plan is worked in order',
        );
      }
      if (!File.fromUri(task.file.uri.resolve(link)).existsSync()) {
        yield (
          file: task.path,
          line: line,
          message: 'the dependency link $link names no file on disk',
        );
      } else if (!known.contains(target)) {
        yield (
          file: task.path,
          line: line,
          message: 'no task numbered ${_padded(target)} is in the plan',
        );
      }
    }
  }
}

/// Reads every task file under [root], in the order a reader would walk them.
List<_Task> _readTasks(Directory root) {
  if (!root.existsSync()) {
    return <_Task>[];
  }
  final List<_Task> tasks = <_Task>[];
  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final String name = _basename(entity.uri);
    final Match? match = _taskFileName.firstMatch(name);
    if (match == null) {
      continue;
    }
    tasks.add((
      number: int.parse(match.group(1)!),
      slug: match.group(2)!,
      path: _display(root, entity),
      file: entity,
      lines: entity.readAsLinesSync(),
    ));
  }
  tasks.sort((_Task a, _Task b) => a.path.compareTo(b.path));
  return tasks;
}

/// The 1-based line of the first line matching [pattern], or 0 for none.
int _lineMatching(List<String> lines, RegExp pattern) {
  for (int index = 0; index < lines.length; index++) {
    if (pattern.hasMatch(lines[index])) {
      return index + 1;
    }
  }
  return 0;
}

/// The 1-based line the `## <section>` heading sits on, or 0 for none.
int _lineOfSection(List<String> lines, String section) {
  for (int index = 0; index < lines.length; index++) {
    if (lines[index].trim() == '## $section') {
      return index + 1;
    }
  }
  return 0;
}

/// The lines of a section, from its heading to the next one.
List<String> _sectionBody(List<String> lines, int start) {
  final List<String> body = <String>[];
  for (int index = start; index < lines.length; index++) {
    if (lines[index].startsWith('## ')) {
      break;
    }
    body.add(lines[index]);
  }
  return body;
}

/// A task number as the plan writes it: three digits.
String _padded(int number) => number.toString().padLeft(3, '0');

/// A file's path as a reader would write it: the plan folder's own name, then
/// the path within it.
String _display(Directory root, File file) {
  final String rootPath = root.uri.toFilePath();
  final String filePath = file.uri.toFilePath();
  final String relative = filePath
      .substring(rootPath.length)
      .split(Platform.pathSeparator)
      .where((String segment) => segment.isNotEmpty)
      .join('/');
  return '${_displayRoot(root)}/$relative';
}

/// The plan folder's own name, without whatever path was used to reach it.
String _displayRoot(Directory root) => _basename(root.uri);

/// The phase folder a task file sits in.
String _parentOf(String path) {
  final List<String> segments = path.split('/');
  return segments.take(segments.length - 1).join('/');
}

/// The last segment of a URI's path, so the host's separator never has to be
/// spelled out.
String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}

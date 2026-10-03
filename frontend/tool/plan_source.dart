import 'dart:io';

/// A step that is one prompt file: `NN-slug.md`, holding its tasks under
/// `## NNN — Title` headings in implementation order.
final RegExp _stepFile = RegExp(r'^(\d{2})-([a-z0-9]+(?:-[a-z0-9]+)*)\.md$');

/// A step that is a folder of prompt files, one per task.
final RegExp _stepFolder = RegExp(r'^(\d{2})-([a-z0-9]+(?:-[a-z0-9]+)*)$');

/// One task's prompt file inside a step folder: `NN-slug.md`, numbered on from
/// the folder's own step number (`27-hardening/27-…`, `28-…`), with the task's
/// stable ID in its `# NNN — Title` heading.
final RegExp _folderFile = RegExp(r'^(\d{2})-([a-z0-9]+(?:-[a-z0-9]+)*)\.md$');

/// A line opening or closing a fenced code block, inside which nothing is a
/// heading, a checkbox or metadata.
final RegExp _fence = RegExp(r'^\s*(```|~~~)');

/// An ATX heading: its level and its text.
final RegExp _heading = RegExp(r'^(#{1,6})\s+(.*?)\s*$');

/// A numbered heading's text: `01 — Step title` or `001 — Task title`.
final RegExp _numbered = RegExp(r'^(\d+) [—–-] (.+)$');

/// A Definition of done entry, ticked or not, with something to tick.
final RegExp _box = RegExp(r'^\s*- \[([ xX])\] \S');

/// Anything shaped like a checkbox, so a malformed one is reported rather
/// than silently left out of the count.
final RegExp _boxLike = RegExp(r'^\s*[-*+]\s*\[');

/// One dependency link: `[003](03-design-system.md)`.
final RegExp _dependency = RegExp(r'\[(\d{3})\]\(([^)]+)\)');

/// The only spelling of the started marker.
const String _startedMarker = '**Implementation started:** Yes';

/// The sections every task has to carry.
const List<String> _requiredSections = <String>[
  'Implement',
  'Files',
  'Definition of done',
];

/// One thing wrong with the plan, and the file and line that has to change.
typedef PlanProblem = ({String file, int line, String message});

/// The only completion states. Readiness is derived separately from
/// dependencies.
enum PlanStatus {
  /// Every acceptance checkbox is checked.
  complete('Complete'),

  /// Some boxes are checked, or the task is explicitly marked as started.
  partial('Partially complete'),

  /// No boxes are checked and the task has not started.
  pending('Pending');

  const PlanStatus(this.label);

  /// How the status is written in the plan and the tracker.
  final String label;
}

/// One task, read from its prompt. Checklist contents are never changed here.
final class PlanTask {
  PlanTask._({
    required this.id,
    required this.title,
    required this.path,
    required this.file,
    required this.line,
    required this.inStepFile,
    required this.position,
    required this.checked,
    required this.total,
    required this.started,
  });

  /// The stable three-digit ID.
  final String id;

  /// The title after the ID in the task's heading.
  final String title;

  /// The prompt file holding the task, relative to the plan root.
  final String path;

  /// That file on disk.
  final File file;

  /// The line the task's heading sits on.
  final int line;

  /// Whether the task is one of several in a step file rather than a prompt
  /// file of its own.
  final bool inStepFile;

  /// Checked Definition of done boxes.
  final int checked;

  /// All Definition of done boxes.
  final int total;

  /// Whether the task carries the explicit started marker.
  final bool started;

  /// The implementation position, `PP.SS`: the step, then the task's place in
  /// it.
  final String position;

  /// The tasks this one depends on, all earlier in the plan.
  final List<PlanTask> dependencies = <PlanTask>[];

  /// The task's link target relative to the plan root: its heading inside a
  /// step file, or its own prompt file.
  String get href =>
      inStepFile ? '$path#${headingAnchor('$id — $title')}' : path;

  /// Complete, Partially complete or Pending, from the checklist alone.
  PlanStatus get status => checked == total
      ? PlanStatus.complete
      : checked > 0 || started
      ? PlanStatus.partial
      : PlanStatus.pending;

  /// Prerequisites that are not complete yet.
  List<PlanTask> get blockers => dependencies
      .where((PlanTask task) => task.status != PlanStatus.complete)
      .toList();
}

/// One implementation step: a prompt file of tasks, or a folder of task
/// prompt files.
final class PlanStep {
  PlanStep._(this.number, this.title, this.path, this.tasks);

  /// The two-digit step number.
  final String number;

  /// The step's title.
  final String title;

  /// The step file or folder, relative to the plan root.
  final String path;

  /// The step's tasks in implementation order.
  final List<PlanTask> tasks;

  /// Complete when every task is, Pending when every task is, and Partially
  /// complete otherwise.
  PlanStatus get status => tasks.isEmpty
      ? PlanStatus.pending
      : tasks.every((PlanTask task) => task.status == PlanStatus.complete)
      ? PlanStatus.complete
      : tasks.every((PlanTask task) => task.status == PlanStatus.pending)
      ? PlanStatus.pending
      : PlanStatus.partial;
}

/// The whole plan as read from disk, with every problem found reading it.
final class PlanSource {
  PlanSource._(this.root, this.steps, this.problems);

  /// The plan directory.
  final Directory root;

  /// The steps in implementation order.
  final List<PlanStep> steps;

  /// Every way the plan contradicts itself, each with its file and line.
  final List<PlanProblem> problems;

  /// Every task in implementation order.
  List<PlanTask> get tasks => <PlanTask>[
    for (final PlanStep step in steps) ...step.tasks,
  ];
}

/// The anchor a Markdown renderer gives a heading: lower case, punctuation
/// dropped and spaces turned into hyphens, the way GitHub writes it.
String headingAnchor(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}\p{Pc} -]', unicode: true), '')
    .replaceAll(' ', '-');

/// Reads every step and task under [root] and checks the plan against itself:
/// stray files, step numbering and headings, task headings, required sections,
/// tickable checklists, metadata, unique IDs and titles without holes, and
/// dependencies that resolve to earlier tasks.
///
/// Reports every problem rather than stopping at the first.
PlanSource readPlan(Directory root) {
  final _Reader reader = _Reader(root);
  return PlanSource._(root, reader.read(), reader.problems);
}

/// One task's lines before they are checked: where it starts and at which
/// heading level.
typedef _Block = ({
  String id,
  String title,
  String? slug,
  String path,
  File file,
  int line,
  int level,
  List<String> lines,
});

/// A step file or folder found in the plan root, with its number and slug.
typedef _Found = ({String number, String slug, FileSystemEntity entity});

/// A dependency link as written, before it is resolved.
typedef _Link = ({String id, String target, int line});

class _Reader {
  _Reader(this.root) : rootName = _basename(root.uri);

  final Directory root;
  final String rootName;
  final List<PlanProblem> problems = <PlanProblem>[];
  final Map<PlanTask, List<_Link>> _links = <PlanTask, List<_Link>>{};
  final Map<PlanTask, String> _slugs = <PlanTask, String>{};

  void _problem(String path, int line, String message) {
    problems.add((
      file: path.isEmpty ? rootName : '$rootName/$path',
      line: line,
      message: message,
    ));
  }

  List<PlanStep> read() {
    if (!root.existsSync()) {
      _problem('', 0, 'there is no plan directory here to check');
      return <PlanStep>[];
    }
    final List<_Found> found = <_Found>[];
    for (final FileSystemEntity entity in root.listSync(followLinks: false)) {
      final String name = _basename(entity.uri);
      if (name.startsWith('.')) {
        continue;
      }
      final RegExpMatch? match = entity is File
          ? _stepFile.firstMatch(name)
          : entity is Directory
          ? _stepFolder.firstMatch(name)
          : null;
      if (match == null) {
        _problem(
          name,
          0,
          entity is Link
              ? 'symbolic links are not supported in the plan'
              : 'only NN-slug.md step files and NN-slug/ step folders belong '
                    'in the plan',
        );
        continue;
      }
      found.add((
        number: match.group(1)!,
        slug: match.group(2)!,
        entity: entity,
      ));
    }
    found.sort(
      (_Found a, _Found b) =>
          _basename(a.entity.uri).compareTo(_basename(b.entity.uri)),
    );
    if (found.isEmpty) {
      _problem('', 0, 'the plan holds no NN-slug.md step file or step folder');
      return <PlanStep>[];
    }

    final List<PlanStep> steps = <PlanStep>[];
    final Set<String> numbers = <String>{};
    for (final _Found step in found) {
      final String name = _basename(step.entity.uri);
      if (!numbers.add(step.number)) {
        _problem(
          name,
          0,
          'step ${step.number} is used twice; a number names one step',
        );
      }
      final FileSystemEntity entity = step.entity;
      final ({String title, List<_Block> blocks}) read = entity is File
          ? _readStepFile(entity, name, step.number, step.slug)
          : _readStepFolder(entity as Directory, name, step.number, step.slug);
      steps.add(
        PlanStep._(step.number, read.title, name, <PlanTask>[
          for (int index = 0; index < read.blocks.length; index++)
            _task(read.blocks[index], '${step.number}.${_pad(index + 1, 2)}'),
        ]),
      );
    }
    final int highestStep = numbers.map(int.parse).reduce(_max);
    for (int number = 1; number <= highestStep; number++) {
      if (!numbers.contains(_pad(number, 2))) {
        _problem(
          '',
          0,
          'the plan runs to step ${_pad(highestStep, 2)} but has no step '
              '${_pad(number, 2)}; steps are numbered consecutively from 01',
        );
      }
    }

    final List<PlanTask> tasks = <PlanTask>[
      for (final PlanStep step in steps) ...step.tasks,
    ];
    if (tasks.isEmpty) {
      _problem('', 0, 'the plan holds no task');
      return steps;
    }
    _checkIdentity(tasks);
    _resolveDependencies(tasks);
    return steps;
  }

  ({String title, List<_Block> blocks}) _readStepFile(
    File file,
    String path,
    String number,
    String slug,
  ) {
    final List<String> lines = _lines(file);
    String title = _humanise(slug);
    final List<_Block> blocks = <_Block>[];
    ({String id, String title, int start})? open;
    void close(int end) {
      final ({String id, String title, int start})? task = open;
      if (task != null) {
        blocks.add((
          id: task.id,
          title: task.title,
          slug: null,
          path: path,
          file: file,
          line: task.start + 1,
          level: 2,
          lines: lines.sublist(task.start, end),
        ));
      }
    }

    bool fenced = false;
    bool headed = false;
    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index];
      if (_fence.hasMatch(line)) {
        fenced = !fenced;
        continue;
      }
      final RegExpMatch? heading = fenced ? null : _heading.firstMatch(line);
      if (heading == null) {
        if (!headed && line.trim().isNotEmpty) {
          headed = true;
          _problem(path, index + 1, _noStepHeading);
        }
        continue;
      }
      final int level = heading.group(1)!.length;
      final RegExpMatch? numbered = _numbered.firstMatch(heading.group(2)!);
      if (!headed) {
        headed = true;
        if (level != 1 || numbered == null) {
          _problem(path, index + 1, _noStepHeading);
        } else if (numbered.group(1) != number) {
          _problem(
            path,
            index + 1,
            'the heading says step ${numbered.group(1)} and the filename says '
            '$number; renaming a file means renaming its heading',
          );
        } else {
          title = numbered.group(2)!.trim();
        }
        if (level == 1) {
          continue;
        }
      }
      if (level == 1) {
        _problem(
          path,
          index + 1,
          'a step file has one `# ` heading, its first line',
        );
        continue;
      }
      if (level != 2) {
        continue;
      }
      if (numbered != null && numbered.group(1)!.length == 3) {
        close(index);
        open = (
          id: numbered.group(1)!,
          title: numbered.group(2)!.trim(),
          start: index,
        );
      } else if (open != null) {
        _problem(
          path,
          index + 1,
          'after the first task every `## ` heading starts a task: '
          '`## NNN — Title`',
        );
      }
    }
    close(lines.length);
    return (title: title, blocks: blocks);
  }

  ({String title, List<_Block> blocks}) _readStepFolder(
    Directory folder,
    String path,
    String number,
    String slug,
  ) {
    final List<_Block> blocks = <_Block>[];
    final List<FileSystemEntity> entries =
        folder
            .listSync(followLinks: false)
            .where(
              (FileSystemEntity entity) =>
                  !_basename(entity.uri).startsWith('.'),
            )
            .toList()
          ..sort(
            (FileSystemEntity a, FileSystemEntity b) =>
                _basename(a.uri).compareTo(_basename(b.uri)),
          );
    int expected = int.parse(number);
    for (final FileSystemEntity entity in entries) {
      final String name = _basename(entity.uri);
      final RegExpMatch? match = entity is File
          ? _folderFile.firstMatch(name)
          : null;
      if (match == null) {
        _problem(
          '$path/$name',
          0,
          'only NN-slug.md prompt files belong in a step folder',
        );
        continue;
      }
      final String taskPath = '$path/$name';
      final int prefix = int.parse(match.group(1)!);
      if (prefix != expected) {
        _problem(
          taskPath,
          0,
          'the file is numbered ${match.group(1)} where ${_pad(expected, 2)} '
          'comes next; prompt files in a step folder are numbered on from the '
          'step number, $number',
        );
      }
      expected = prefix + 1;
      final List<String> lines = _lines(entity as File);
      int start = -1;
      bool fenced = false;
      for (int index = 0; index < lines.length; index++) {
        if (_fence.hasMatch(lines[index])) {
          fenced = !fenced;
          continue;
        }
        if (fenced) {
          continue;
        }
        final RegExpMatch? heading = _heading.firstMatch(lines[index]);
        if (heading == null || heading.group(1)!.length != 1) {
          continue;
        }
        if (start >= 0) {
          _problem(taskPath, index + 1, 'a task file has one `# ` heading');
          continue;
        }
        start = index;
      }
      final RegExpMatch? numbered = start < 0
          ? null
          : _numbered.firstMatch(_heading.firstMatch(lines[start])!.group(2)!);
      if (numbered == null || numbered.group(1)!.length != 3) {
        _problem(
          taskPath,
          start < 0 ? 1 : start + 1,
          'no heading of the form `# NNN — Title`, so nothing in the file says '
          'which task it is',
        );
        continue;
      }
      blocks.add((
        id: numbered.group(1)!,
        title: numbered.group(2)!.trim(),
        slug: match.group(2),
        path: taskPath,
        file: entity,
        line: start + 1,
        level: 1,
        lines: lines.sublist(start),
      ));
    }
    return (title: _humanise(slug), blocks: blocks);
  }

  /// Checks one task's sections, checklist and metadata, and builds it at
  /// [position].
  PlanTask _task(_Block block, String position) {
    final String sectionMark = '#' * (block.level + 1);
    final Map<String, List<int>> sections = <String, List<int>>{};
    final List<int> starts = <int>[];
    final List<_Link> links = <_Link>[];
    int checked = 0;
    int total = 0;
    bool inDone = false;
    bool fenced = false;
    for (int index = 1; index < block.lines.length; index++) {
      final String line = block.lines[index];
      final int lineNumber = block.line + index;
      if (_fence.hasMatch(line)) {
        fenced = !fenced;
        continue;
      }
      if (fenced) {
        continue;
      }
      final RegExpMatch? heading = _heading.firstMatch(line);
      if (heading != null && heading.group(1)!.length <= block.level + 1) {
        final String text = heading.group(2)!;
        inDone =
            heading.group(1) == sectionMark && text == 'Definition of done';
        if (heading.group(1) == sectionMark) {
          sections.putIfAbsent(text, () => <int>[]).add(lineNumber);
        }
        continue;
      }
      if (inDone) {
        final RegExpMatch? box = _box.firstMatch(line);
        if (box != null) {
          total++;
          if (box.group(1)!.toLowerCase() == 'x') {
            checked++;
          }
        } else if (_boxLike.hasMatch(line)) {
          _problem(
            block.path,
            lineNumber,
            'malformed Definition of done checkbox: ${line.trim()}',
          );
        }
        continue;
      }
      final String trimmed = line.trimLeft();
      if (trimmed.startsWith('**Implementation started')) {
        starts.add(lineNumber);
        if (trimmed.trimRight() != _startedMarker) {
          _problem(
            block.path,
            lineNumber,
            'write exactly $_startedMarker, or omit it',
          );
        }
      } else if (trimmed.startsWith('**Implementation step')) {
        _problem(
          block.path,
          lineNumber,
          'positions are no longer written into prompts; a task\'s position '
          'is its place in the plan',
        );
      } else if (trimmed.startsWith('**Depends on**')) {
        final String list = trimmed
            .substring('**Depends on**'.length)
            .split('|')
            .first;
        for (final RegExpMatch match in _dependency.allMatches(list)) {
          links.add((
            id: match.group(1)!,
            target: match.group(2)!,
            line: lineNumber,
          ));
        }
        final String rest = list
            .replaceAll(_dependency, '')
            .replaceAll(',', '')
            .trim();
        if (rest.isNotEmpty && rest != 'None' && rest != '—') {
          _problem(
            block.path,
            lineNumber,
            'a Depends on line holds only `[NNN](path)` links',
          );
        }
      }
    }
    if (starts.length > 1) {
      _problem(
        block.path,
        starts[1],
        'the started marker is written more than once',
      );
    }
    for (final String section in _requiredSections) {
      final List<int>? found = sections[section];
      if (found == null) {
        _problem(block.path, block.line, 'no `$sectionMark $section` section');
      } else if (found.length > 1) {
        _problem(
          block.path,
          found[1],
          'more than one `$sectionMark $section` section',
        );
      }
    }
    if (sections.containsKey('Definition of done') && total == 0) {
      _problem(
        block.path,
        sections['Definition of done']!.first,
        'the Definition of done has no checkbox, so nothing about this task '
        'can be ticked off',
      );
    }
    final PlanTask task = PlanTask._(
      id: block.id,
      title: block.title,
      path: block.path,
      file: block.file,
      line: block.line,
      inStepFile: block.level == 2,
      position: position,
      checked: checked,
      total: total,
      started: starts.isNotEmpty,
    );
    if (block.slug != null) {
      _slugs[task] = block.slug!;
    }
    _links[task] = links;
    return task;
  }

  /// Reports an ID used twice, a hole in the IDs, and a title or slug used
  /// twice.
  ///
  /// Contiguity matters because the plan is the backlog (FE-FLOW-08): a gap is
  /// a task somebody deleted without saying so, or one never written.
  void _checkIdentity(List<PlanTask> tasks) {
    final Map<String, PlanTask> byId = <String, PlanTask>{};
    final Map<String, PlanTask> byTitle = <String, PlanTask>{};
    final Map<String, PlanTask> bySlug = <String, PlanTask>{};
    for (final PlanTask task in tasks) {
      final PlanTask sameId = byId.putIfAbsent(task.id, () => task);
      if (sameId != task) {
        _problem(
          task.path,
          task.line,
          'task ${task.id} is also $rootName/${sameId.path}:${sameId.line}; a '
          'number names one task',
        );
      }
      final PlanTask sameTitle = byTitle.putIfAbsent(
        task.title.toLowerCase(),
        () => task,
      );
      if (sameTitle != task) {
        _problem(
          task.path,
          task.line,
          'the title "${task.title}" is also task ${sameTitle.id}; a title '
          'names one task',
        );
      }
      final String? slug = _slugs[task];
      if (slug != null) {
        final PlanTask sameSlug = bySlug.putIfAbsent(slug, () => task);
        if (sameSlug != task) {
          _problem(
            task.path,
            task.line,
            'the slug $slug is also $rootName/${sameSlug.path}; a slug names '
            'one task',
          );
        }
      }
    }
    final int highest = byId.keys.map(int.parse).reduce(_max);
    for (int number = 1; number <= highest; number++) {
      if (!byId.containsKey(_pad(number, 3))) {
        _problem(
          '',
          0,
          'the plan runs to task ${_pad(highest, 3)} but has no task '
              '${_pad(number, 3)}; the task numbering has a hole in it',
        );
      }
    }
  }

  /// Resolves each dependency link to the task it names, reporting one that
  /// names no file, names a file not holding that task, repeats, or does not
  /// point to an earlier task.
  ///
  /// A plan is worked top to bottom, so a task may only rest on one already
  /// finished. A forward link is a cycle waiting to be discovered.
  void _resolveDependencies(List<PlanTask> tasks) {
    final Map<String, int> position = <String, int>{};
    final Map<String, PlanTask> byId = <String, PlanTask>{};
    for (int index = 0; index < tasks.length; index++) {
      position.putIfAbsent(tasks[index].id, () => index);
      byId.putIfAbsent(tasks[index].id, () => tasks[index]);
    }
    for (final PlanTask task in tasks) {
      for (final _Link link in _links[task]!) {
        final PlanTask? target = byId[link.id];
        final String path = link.target.split('#').first;
        final File file = File.fromUri(task.file.uri.resolve(path));
        if (target != null && position[target.id]! >= position[task.id]!) {
          _problem(
            task.path,
            link.line,
            'depends on task ${link.id}, which does not appear earlier than '
            '${task.id} in the plan; the plan is worked in order',
          );
        }
        if (!file.existsSync()) {
          _problem(
            task.path,
            link.line,
            'the dependency link ${link.target} names no file on disk',
          );
          continue;
        }
        if (target == null) {
          _problem(
            task.path,
            link.line,
            'no task numbered ${link.id} is in the plan',
          );
          continue;
        }
        if (file.uri.normalizePath() != target.file.uri.normalizePath()) {
          _problem(
            task.path,
            link.line,
            'the dependency link ${link.target} does not hold task ${link.id}, '
            'which is in $rootName/${target.path}',
          );
          continue;
        }
        if (task.dependencies.contains(target)) {
          _problem(task.path, link.line, 'task ${link.id} is listed twice');
          continue;
        }
        if (position[target.id]! < position[task.id]!) {
          task.dependencies.add(target);
        }
      }
    }
  }
}

const String _noStepHeading =
    'no heading of the form `# NN — Step title` on the first line, so nothing '
    'in the file says which step it is';

/// A file's lines, whatever line endings it was saved with.
List<String> _lines(File file) =>
    file.readAsStringSync().replaceAll('\r\n', '\n').split('\n');

/// A step folder's title from its slug: `27-hardening` reads "Hardening".
String _humanise(String slug) {
  final String words = slug.replaceAll('-', ' ');
  return '${words[0].toUpperCase()}${words.substring(1)}';
}

int _max(int a, int b) => a > b ? a : b;

String _pad(int number, int width) => number.toString().padLeft(width, '0');

/// The last segment of a URI's path, so the host's separator never has to be
/// spelled out.
String _basename(Uri uri) =>
    uri.pathSegments.where((String segment) => segment.isNotEmpty).last;

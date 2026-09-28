import 'dart:io';

const String generatedStart = '<!-- dev-plan:generated:start -->';
const String generatedEnd = '<!-- dev-plan:generated:end -->';
const String _usage =
    'usage: dart run tool/sync_dev_tracker.dart [--check] [--root <repo-root>]';
final RegExp _taskName = RegExp(r'^(\d{3})-(.+)\.md$');
final RegExp _phaseName = RegExp(r'^(\d{2})-(.+)$');
final RegExp _box = RegExp(r'^\s*- \[([ xX])\] \S');
final RegExp _dependency = RegExp(r'\[(\d{3})\]\(([^)]+)\)');

/// The only completion states. Readiness is derived separately from dependencies.
enum PlanStatus {
  complete('Complete'),
  partial('Partially complete'),
  pending('Pending');

  const PlanStatus(this.label);
  final String label;
}

/// Validated task metadata; checklist contents are never changed by this tool.
class PlanTask {
  PlanTask({
    required this.file,
    required this.relativePath,
    required this.id,
    required this.title,
    required this.step,
    required this.content,
    required this.checked,
    required this.total,
    required this.started,
    required this.links,
  });

  final File file;
  final String relativePath;
  final String id;
  final String title;
  final String step;
  final String content;
  final int checked;
  final int total;
  final bool started;
  final List<({String id, String path})> links;
  final List<PlanTask> dependencies = <PlanTask>[];

  PlanStatus get status => checked == total
      ? PlanStatus.complete
      : checked > 0 || started
      ? PlanStatus.partial
      : PlanStatus.pending;

  List<PlanTask> get blockers => dependencies
      .where((PlanTask task) => task.status != PlanStatus.complete)
      .toList();
}

class PlanPhase {
  PlanPhase(this.directory, this.number, this.title, this.readme, this.tasks);

  final Directory directory;
  final String number;
  final String title;
  final String readme;
  final List<PlanTask> tasks;

  String get name => _basename(directory.uri);
  PlanStatus get status => tasks.isEmpty
      ? PlanStatus.pending
      : tasks.every((PlanTask task) => task.status == PlanStatus.complete)
      ? PlanStatus.complete
      : tasks.every((PlanTask task) => task.status == PlanStatus.pending)
      ? PlanStatus.pending
      : PlanStatus.partial;
}

/// All outputs are prepared and validated before the first file is written.
class TrackerSnapshot {
  TrackerSnapshot(this.root, this.phases, this.outputs);

  final Directory root;
  final List<PlanPhase> phases;
  final Map<String, String> outputs;

  List<PlanTask> get tasks => <PlanTask>[
    for (final PlanPhase phase in phases) ...phase.tasks,
  ];

  List<String> get stalePaths => <String>[
    for (final MapEntry<String, String> output in outputs.entries)
      if (!_matches(File('${root.path}/${output.key}'), output.value))
        output.key,
  ];

  /// Replaces only changed files, preserving timestamps on an unchanged run.
  List<String> write() {
    final List<String> changed = stalePaths;
    for (final String path in changed) {
      final File target = File('${root.path}/$path');
      final File temporary = File('${target.path}.sync-$pid.tmp');
      try {
        temporary.writeAsStringSync(outputs[path]!, flush: true);
        temporary.renameSync(target.path);
      } finally {
        if (temporary.existsSync()) {
          temporary.deleteSync();
        }
      }
    }
    return changed;
  }
}

Future<int> main(List<String> args) async {
  bool check = false;
  String? rootPath;
  for (int index = 0; index < args.length; index++) {
    if (args[index] == '--check' && !check) {
      check = true;
    } else if (args[index] == '--root' &&
        rootPath == null &&
        index + 1 < args.length &&
        !args[index + 1].startsWith('--')) {
      rootPath = args[++index];
    } else {
      stderr.writeln(_usage);
      return exitCode = 1;
    }
  }
  try {
    final TrackerSnapshot snapshot = readTracker(
      rootPath == null ? _defaultRoot() : Directory(rootPath),
    );
    final List<String> changed = check ? snapshot.stalePaths : snapshot.write();
    if (check && changed.isNotEmpty) {
      stderr.writeln('dev tracker: generated files are stale:');
      for (final String path in changed) {
        stderr.writeln('  $path');
      }
      stderr.writeln(
        'Run dart run tool/sync_dev_tracker.dart from frontend, then review '
        'and stage the updated plan files.',
      );
      return exitCode = 1;
    }
    stdout.writeln(
      'dev tracker: ${snapshot.phases.length} steps, '
      '${snapshot.tasks.length} tasks; '
      '${check ? 'up to date' : '${changed.length} file(s) refreshed'}',
    );
    return exitCode = 0;
  } on FormatException catch (error) {
    stderr.writeln('dev tracker: ${error.message}');
    return exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('dev tracker: ${error.message}: ${error.path}');
    return exitCode = 1;
  }
}

Directory _defaultRoot() {
  Directory candidate = Directory.current.absolute;
  while (true) {
    if (Directory('${candidate.path}/dev-plan').existsSync()) {
      return candidate;
    }
    if (candidate.parent.path == candidate.path) {
      return File.fromUri(Platform.script).parent.parent.parent;
    }
    candidate = candidate.parent;
  }
}

TrackerSnapshot readTracker(Directory repository) {
  final Directory root = Directory(repository.resolveSymbolicLinksSync());
  final Directory plan = Directory('${root.path}/dev-plan');
  if (!plan.existsSync()) {
    throw const FormatException('missing dev-plan directory');
  }
  _rejectLink(plan.path);
  final List<FileSystemEntity> entities = plan.listSync(
    recursive: true,
    followLinks: false,
  );
  for (final FileSystemEntity entity in entities) {
    _rejectLink(entity.path);
  }
  final List<Directory> directories =
      plan
          .listSync(followLinks: false)
          .whereType<Directory>()
          .where((Directory dir) => _phaseName.hasMatch(_basename(dir.uri)))
          .toList()
        ..sort((Directory a, Directory b) => a.path.compareTo(b.path));
  if (directories.isEmpty) {
    throw const FormatException('no numbered phase folders');
  }
  final List<PlanPhase> phases = <PlanPhase>[];
  final Map<String, PlanTask> byId = <String, PlanTask>{};
  for (int index = 0; index < directories.length; index++) {
    final Directory directory = directories[index];
    final String name = _basename(directory.uri);
    final String number = _phaseName.firstMatch(name)!.group(1)!;
    if (int.parse(number) != index + 1) {
      throw FormatException(
        '$name: folder numbers must be consecutive from 01',
      );
    }
    final File readmeFile = File('${directory.path}/README.md');
    if (!readmeFile.existsSync()) {
      throw FormatException('$name: missing README.md');
    }
    final String readme = _read(readmeFile);
    final RegExpMatch? heading = RegExp(
      '^# $number [—–-] (.+)\$',
      multiLine: true,
    ).firstMatch(readme);
    if (heading == null) {
      throw FormatException('$name/README.md: expected # $number — Title');
    }
    final List<File> files =
        directory
            .listSync(followLinks: false)
            .whereType<File>()
            .where((File file) => _taskName.hasMatch(_basename(file.uri)))
            .toList()
          ..sort((File a, File b) => a.path.compareTo(b.path));
    final List<PlanTask> tasks = <PlanTask>[];
    for (int taskIndex = 0; taskIndex < files.length; taskIndex++) {
      final File file = files[taskIndex];
      final String relative = '$name/${_basename(file.uri)}';
      final PlanTask task = _readTask(
        file,
        relative,
        '$number.${(taskIndex + 1).toString().padLeft(2, '0')}',
      );
      if (byId.containsKey(task.id)) {
        throw FormatException('$relative: duplicate task ID ${task.id}');
      }
      tasks.add(task);
      byId[task.id] = task;
    }
    phases.add(PlanPhase(directory, number, heading.group(1)!, readme, tasks));
  }
  final List<PlanTask> tasks = <PlanTask>[
    for (final PlanPhase phase in phases) ...phase.tasks,
  ];
  final int discovered = entities.whereType<File>().where((File file) {
    return _taskName.hasMatch(_basename(file.uri));
  }).length;
  if (tasks.isEmpty || tasks.length != discovered) {
    throw const FormatException(
      'every task must belong directly to one numbered phase folder',
    );
  }
  final Map<String, int> positions = <String, int>{
    for (int index = 0; index < tasks.length; index++) tasks[index].id: index,
  };
  for (final PlanTask task in tasks) {
    for (final ({String id, String path}) link in task.links) {
      final PlanTask? target = byId[link.id];
      if (target == null ||
          task.file.uri.resolve(link.path).normalizePath() !=
              target.file.uri.normalizePath()) {
        throw FormatException(
          '${task.relativePath}: dangling or mismatched dependency '
          '[${link.id}](${link.path})',
        );
      }
      if (positions[target.id]! >= positions[task.id]!) {
        throw FormatException(
          '${task.relativePath}: dependency ${target.id} must appear earlier '
          'in implementation order (folder/sub-step)',
        );
      }
      if (task.dependencies.contains(target)) {
        throw FormatException(
          '${task.relativePath}: duplicate dependency ${target.id}',
        );
      }
      task.dependencies.add(target);
    }
  }
  final Map<String, String> outputs = <String, String>{
    'dev-tracker.md': _trackerDocument(phases, tasks),
    'dev-plan/INDEX.md': _indexDocument(phases, tasks),
    for (final PlanPhase phase in phases)
      'dev-plan/${phase.name}/README.md': _phaseReadme(phase),
    for (final PlanTask task in tasks)
      'dev-plan/${task.relativePath}': _withStep(task),
  };
  for (final String path in outputs.keys) {
    _rejectLink('${root.path}/$path');
  }
  return TrackerSnapshot(root, phases, outputs);
}

PlanTask _readTask(File file, String relative, String step) {
  final String content = _read(file);
  final List<String> lines = content.split('\n');
  final String id = _taskName.firstMatch(_basename(file.uri))!.group(1)!;
  final RegExpMatch? heading = RegExp(
    '^# $id [—–-] (.+)\$',
    multiLine: true,
  ).firstMatch(content);
  if (heading == null) {
    throw FormatException('$relative: missing or mismatched task heading');
  }
  final List<String> markers = lines
      .where(
        (String line) => line.trimLeft().startsWith('**Implementation started'),
      )
      .toList();
  if (markers.length > 1 ||
      (markers.isNotEmpty &&
          markers.single != '**Implementation started:** Yes')) {
    throw FormatException(
      '$relative: use exactly **Implementation started:** Yes, or omit it',
    );
  }
  final List<int> sections = <int>[
    for (int index = 0; index < lines.length; index++)
      if (lines[index].trim() == '## Definition of done') index,
  ];
  if (sections.length != 1) {
    throw FormatException('$relative: expected one Definition of done section');
  }
  int checked = 0;
  int total = 0;
  for (final String line in lines.skip(sections.single + 1)) {
    if (line.startsWith('## ')) {
      break;
    }
    final RegExpMatch? box = _box.firstMatch(line);
    if (box != null) {
      total++;
      if (box.group(1)!.toLowerCase() == 'x') {
        checked++;
      }
    } else if (RegExp(r'^\s*[-*+]\s*\[').hasMatch(line)) {
      throw FormatException(
        '$relative: malformed Definition of done checkbox: $line',
      );
    }
  }
  if (total == 0) {
    throw FormatException('$relative: Definition of done has no checkboxes');
  }
  final List<({String id, String path})> links = <({String id, String path})>[];
  for (final String line in lines.where(
    (String line) => line.contains('**Depends on**'),
  )) {
    final String dependencies = line
        .split('**Depends on**')
        .last
        .split('|')
        .first;
    links.addAll(
      _dependency
          .allMatches(dependencies)
          .map(
            (RegExpMatch match) => (id: match.group(1)!, path: match.group(2)!),
          ),
    );
    final String remainder = dependencies
        .replaceAll(_dependency, '')
        .replaceAll(',', '')
        .trim();
    if (remainder.isNotEmpty && remainder != 'None' && remainder != '—') {
      throw FormatException('$relative: malformed Depends on metadata');
    }
  }
  return PlanTask(
    file: file,
    relativePath: relative,
    id: id,
    title: heading.group(1)!,
    step: step,
    content: content,
    checked: checked,
    total: total,
    started: markers.isNotEmpty,
    links: links,
  );
}

String _withStep(PlanTask task) {
  final String line = '**Implementation step:** ${task.step}';
  final RegExp metadata = RegExp(
    r'^\*\*Implementation step:\*\*.*$',
    multiLine: true,
  );
  if (metadata.allMatches(task.content).length > 1) {
    throw FormatException(
      '${task.relativePath}: duplicate Implementation step metadata',
    );
  }
  if (metadata.hasMatch(task.content)) {
    return task.content.replaceFirst(metadata, line);
  }
  final int headingEnd = task.content.indexOf('\n');
  return '${task.content.substring(0, headingEnd)}\n\n$line${task.content.substring(headingEnd)}';
}

String _trackerDocument(List<PlanPhase> phases, List<PlanTask> tasks) {
  final int complete = _count(
    tasks.map((PlanTask task) => task.status),
    PlanStatus.complete,
  );
  final int percent = tasks.isEmpty ? 0 : complete * 100 ~/ tasks.length;
  final int prerequisiteReviews = tasks
      .where(
        (PlanTask task) =>
            task.status == PlanStatus.complete && task.blockers.isNotEmpty,
      )
      .length;
  final StringBuffer text = StringBuffer()
    ..writeln('# Tapture — development tracker')
    ..writeln()
    ..writeln(
      '<!-- Generated by frontend/tool/sync_dev_tracker.dart. Do not edit by hand. -->',
    )
    ..writeln()
    ..writeln(
      '**Completed files: $percent%** `${_progressBar(complete, tasks.length, 20)}` **$complete/${tasks.length}**',
    )
    ..writeln()
    ..writeln(
      '**Files:** ${_counts(tasks.map((PlanTask task) => task.status))}.',
    )
    ..writeln()
    ..writeln(
      '**Folders:** ${_counts(phases.map((PlanPhase phase) => phase.status))}.',
    )
    ..writeln()
    ..writeln(_next(tasks, 'dev-plan/'))
    ..writeln();
  if (prerequisiteReviews > 0) {
    text
      ..writeln(
        '**Prerequisite review:** $prerequisiteReviews completed task(s) have unfinished prerequisites; see [dependencies](dev-plan/INDEX.md).',
      )
      ..writeln();
  }
  text
    ..writeln(
      '✅ Complete · ◐ Partially complete · ○ Pending. Bars count completed files, not effort or release readiness.',
    )
    ..writeln()
    ..writeln(
      '| Step / folder | Status | Complete | Partial files | Pending files |',
    )
    ..writeln('| --- | --- | --- | --- | --- |');
  for (final PlanPhase phase in phases) {
    final int done = _count(
      phase.tasks.map((PlanTask task) => task.status),
      PlanStatus.complete,
    );
    final String progress = phase.tasks.isEmpty
        ? '`${_progressBar(0, 0, 10)}` 0/0 (n/a)'
        : '`${_progressBar(done, phase.tasks.length, 10)}` $done/${phase.tasks.length}';
    text.writeln(
      '| ${phase.number} · [${_escape(phase.title)}](dev-plan/${phase.name}/README.md) | ${_statusBadge(phase.status)} | $progress | ${_taskLinks(phase.tasks, PlanStatus.partial)} | ${_taskLinks(phase.tasks, PlanStatus.pending)} |',
    );
  }
  text
    ..writeln()
    ..writeln(
      'Open file IDs are listed above; completed files and acceptance details are in the linked folders or [full index](dev-plan/INDEX.md).',
    )
    ..writeln()
    ..writeln(
      'Generated from task checklists; task creation, verification and pre-commit refresh automatically. [Update rules](dev-plan/STANDARD.md#progress-updates-are-part-of-implementation) · [History](dev-plan/01-orchestration/history/README.md).',
    );
  return text.toString();
}

String _progressBar(int complete, int total, int width) {
  final int filled = total == 0 ? 0 : complete * width ~/ total;
  return ''.padRight(filled, '█').padRight(width, '░');
}

String _statusBadge(PlanStatus status) => switch (status) {
  PlanStatus.complete => '✅ Complete',
  PlanStatus.partial => '◐ Partial',
  PlanStatus.pending => '○ Pending',
};

String _taskLinks(List<PlanTask> tasks, PlanStatus status) {
  final String links = tasks
      .where((PlanTask task) => task.status == status)
      .map((PlanTask task) => '[${task.id}](dev-plan/${task.relativePath})')
      .join(' ');
  return links.isEmpty ? '—' : links;
}

String _indexDocument(List<PlanPhase> phases, List<PlanTask> tasks) {
  const String prefix = '';
  final StringBuffer text = StringBuffer()
    ..writeln('# Tapture — implementation index')
    ..writeln()
    ..writeln(
      '<!-- Generated by frontend/tool/sync_dev_tracker.dart. Do not edit by hand. -->',
    )
    ..writeln()
    ..writeln(
      'Follow the numbered folders and sub-steps in order. Stable task IDs stay unchanged when a task moves; **PP.SS** identifies its current implementation position.',
    )
    ..writeln()
    ..writeln(
      'Completion comes only from each task’s **Definition of done**: **Complete** = every criterion checked; **Partially complete** = some checked or `**Implementation started:** Yes`; **Pending** = no checks and no started marker. A folder is Complete when all its tasks are Complete, Pending when all are Pending, and Partially complete otherwise. Dependency readiness is separate from completion.',
    )
    ..writeln()
    ..writeln(
      'Update the task checklist after implementation and verification; mark started work explicitly when no acceptance criterion is met yet. Run `dart run tool/sync_dev_tracker.dart` from `frontend/` to refresh this tracker, the index, phase summaries and implementation positions. Verification and the installed pre-commit hook refresh them automatically; CI rejects stale generated files. Never tick a criterion simply to make the tracker green.',
    )
    ..writeln()
    ..writeln(
      '**Steps:** ${_counts(phases.map((PlanPhase phase) => phase.status))}.',
    )
    ..writeln(
      'Historical implementation claims and audit limitations are preserved '
      'in [status history](${prefix}01-orchestration/history/README.md).',
    )
    ..writeln(
      '**Sub-steps:** ${_counts(tasks.map((PlanTask task) => task.status))}.',
    )
    ..writeln()
    ..writeln(_next(tasks, prefix))
    ..writeln()
    ..writeln('## Implementation flow')
    ..writeln()
    ..writeln(
      '| Step | Folder | Status | Complete | Partially complete | Pending | Sub-steps |',
    )
    ..writeln('| --- | --- | --- | ---: | ---: | ---: | ---: |');
  for (final PlanPhase phase in phases) {
    final List<PlanStatus> states = phase.tasks
        .map((PlanTask task) => task.status)
        .toList();
    text.writeln(
      '| ${phase.number} | [${_escape(phase.title)}]($prefix${phase.name}/README.md) | **${phase.status.label}** | ${_count(states, PlanStatus.complete)} | ${_count(states, PlanStatus.partial)} | ${_count(states, PlanStatus.pending)} | ${states.length} |',
    );
  }
  for (final PlanPhase phase in phases) {
    text
      ..writeln()
      ..writeln('## ${phase.number} — ${phase.title}')
      ..writeln()
      ..writeln(
        '**${phase.status.label}** · `${phase.name}/` · ${_counts(phase.tasks.map((PlanTask task) => task.status))}.',
      )
      ..writeln()
      ..write(
        _taskTable(
          phase.tasks,
          (PlanTask task) => '$prefix${task.relativePath}',
        ),
      );
  }
  return text.toString();
}

String _phaseReadme(PlanPhase phase) {
  final String block =
      '$generatedStart\n\n'
      '## Implementation progress\n\n'
      '**Step ${phase.number} — ${phase.status.label}**\n\n'
      '${_counts(phase.tasks.map((PlanTask task) => task.status))}. '
      'Status is generated from each task’s Definition of done; '
      'follow sub-step order below.\n\n'
      '${_taskTable(phase.tasks, (PlanTask task) => _basename(task.file.uri))}'
      '\n$generatedEnd';
  final int starts = generatedStart.allMatches(phase.readme).length;
  final int ends = generatedEnd.allMatches(phase.readme).length;
  if (starts == 0 && ends == 0) {
    return '${phase.readme.trimRight()}\n\n$block\n';
  }
  final int start = phase.readme.indexOf(generatedStart);
  final int end = phase.readme.indexOf(generatedEnd);
  if (starts != 1 || ends != 1 || end < start) {
    throw FormatException(
      '${phase.name}/README.md: malformed generated markers',
    );
  }
  return phase.readme.replaceRange(start, end + generatedEnd.length, block);
}

String _taskTable(List<PlanTask> tasks, String Function(PlanTask) link) {
  final StringBuffer text = StringBuffer()
    ..writeln(
      '| Sub-step | Task ID | File / implementation | Status | Done | Dependencies / readiness |',
    )
    ..writeln('| --- | --- | --- | --- | ---: | --- |');
  for (final PlanTask task in tasks) {
    final String dependencies = task.dependencies.isEmpty
        ? 'None'
        : task.dependencies
              .map(
                (PlanTask dependency) =>
                    '${dependency.step} (${dependency.id})',
              )
              .join(', ');
    final List<PlanTask> blockers = task.blockers;
    final String readiness = blockers.isNotEmpty
        ? '${task.status == PlanStatus.complete ? 'Prerequisite review' : 'Waiting for'}: ${blockers.map((PlanTask task) => task.id).join(', ')}'
        : task.status == PlanStatus.complete
        ? 'Dependencies complete'
        : 'Ready';
    text.writeln(
      '| ${task.step} | ${task.id} | [${_escape(task.title)}](${link(task)}) | **${task.status.label}** | ${task.checked}/${task.total} | $dependencies; $readiness |',
    );
  }
  return text.toString();
}

String _next(List<PlanTask> tasks, String prefix) {
  final List<PlanTask> unfinished = tasks
      .where((PlanTask task) => task.status != PlanStatus.complete)
      .toList();
  if (unfinished.isEmpty) {
    return '**Next actionable sub-step:** None — all tasks are complete.';
  }
  final List<PlanTask> ready = unfinished
      .where((PlanTask task) => task.blockers.isEmpty)
      .toList();
  if (ready.isEmpty) {
    return '**Next actionable sub-step:** None — unfinished tasks have incomplete dependencies.';
  }
  final PlanTask next = ready.first;
  return '**Next actionable sub-step:** [${next.step} · ${next.id} — ${next.title}]($prefix${next.relativePath}) (${next.status.label}; dependencies complete).';
}

String _counts(Iterable<PlanStatus> statuses) {
  final List<PlanStatus> values = statuses.toList();
  return '${values.length} total · ${_count(values, PlanStatus.complete)} Complete · ${_count(values, PlanStatus.partial)} Partially complete · ${_count(values, PlanStatus.pending)} Pending';
}

int _count(Iterable<PlanStatus> statuses, PlanStatus status) =>
    statuses.where((PlanStatus value) => value == status).length;
String _escape(String value) =>
    value.replaceAll('|', r'\|').replaceAll('[', r'\[').replaceAll(']', r'\]');
String _basename(Uri uri) =>
    uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
String _read(File file) => file.readAsStringSync().replaceAll('\r\n', '\n');
bool _matches(File file, String content) =>
    file.existsSync() && _read(file) == content;
void _rejectLink(String path) {
  if (FileSystemEntity.typeSync(path, followLinks: false) ==
      FileSystemEntityType.link) {
    throw FormatException(
      '$path: symbolic links are not supported in plan inputs or outputs',
    );
  }
}

import 'dart:io';

/// One deferred item in the backlog.
final class BacklogItem {
  /// Creates an item.
  const BacklogItem({
    required this.phase,
    required this.title,
    required this.reason,
    required this.revisit,
    required this.source,
    this.defect = false,
  });

  /// Phase heading.
  final String phase;

  /// Task or waiver title.
  final String title;

  /// Why it is deferred. Empty is a defect.
  final String reason;

  /// When to look at it again.
  final String revisit;

  /// Plan file, friction log or release record.
  final String source;

  /// True when [reason] was never stated.
  final bool defect;
}

/// Reads unticked tasks, friction lines and waived gates.
List<BacklogItem> collectBacklog({
  required Directory plan,
  File? friction,
  File? releaseRecord,
}) {
  final List<BacklogItem> items = <BacklogItem>[];
  final List<File> files = plan
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) => file.path.endsWith('.md'))
      .toList();
  for (final File file in files) {
    String phase = file.parent.path.split(Platform.pathSeparator).last;
    final List<String> lines = file.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      final String line = lines[index];
      if (line.startsWith('# ')) phase = line.substring(2).trim();
      if (!line.startsWith('- [ ]')) continue;
      final String title = line.replaceFirst('- [ ]', '').trim();
      final String following = index + 1 < lines.length ? lines[index + 1].trim() : '';
      final bool stated = following.startsWith('because:');
      items.add(
        BacklogItem(
          phase: phase,
          title: title,
          reason: stated ? following.substring('because:'.length).trim() : '',
          revisit: stated ? 'when the reason no longer holds' : '',
          source: file.path,
          defect: !stated,
        ),
      );
    }
  }
  if (friction != null && friction.existsSync()) {
    for (final String line in friction.readAsLinesSync()) {
      if (!line.startsWith('- ')) continue;
      final List<String> parts = line.substring(2).split('|');
      items.add(
        BacklogItem(
          phase: 'friction',
          title: parts.length > 1 ? parts[1].trim() : line,
          reason: parts.length > 2 ? parts[2].trim() : '',
          revisit: parts.length > 3 ? parts[3].trim() : '',
          source: friction.path,
          defect: parts.length < 3 || parts[2].trim().isEmpty,
        ),
      );
    }
  }
  if (releaseRecord != null && releaseRecord.existsSync()) {
    for (final String line in releaseRecord.readAsLinesSync()) {
      if (!line.contains('| waived |')) continue;
      final List<String> cells = line
          .split('|')
          .map((String cell) => cell.trim())
          .where((String cell) => cell.isNotEmpty)
          .toList();
      final String reason = cells.length > 2 ? cells[2] : '';
      items.add(
        BacklogItem(
          phase: 'release',
          title: cells.isEmpty ? 'waiver' : cells.first,
          reason: reason,
          revisit: 'next release',
          source: releaseRecord.path,
          defect: reason.isEmpty,
        ),
      );
    }
  }
  items.sort((BacklogItem a, BacklogItem b) {
    final int byPhase = a.phase.compareTo(b.phase);
    return byPhase != 0 ? byPhase : a.title.compareTo(b.title);
  });
  return items;
}

/// Writes [items] to `build/backlog.md`.
void writeBacklog(List<BacklogItem> items, {Directory? out}) {
  final Directory target = out ?? Directory('build');
  target.createSync(recursive: true);
  final StringBuffer buffer = StringBuffer('# Backlog\n\n');
  String? phase;
  for (final BacklogItem item in items) {
    if (item.phase != phase) {
      phase = item.phase;
      buffer.writeln('## $phase\n');
    }
    final String reason = item.defect
        ? 'defect: no deferral reason'
        : item.reason;
    buffer.writeln(
      '- ${item.title} — $reason. Revisit: ${item.revisit}. Source: ${item.source}',
    );
  }
  File('${target.path}/backlog.md').writeAsStringSync(buffer.toString());
}

Future<int> main(List<String> args) async {
  final Directory plan = Directory(args.isEmpty ? '../dev-plan' : args.first);
  collectBacklog(plan: plan);
  writeBacklog(collectBacklog(plan: plan));
  return 0;
}

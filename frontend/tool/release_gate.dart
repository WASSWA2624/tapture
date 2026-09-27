import 'dart:io';

/// One row of the release record.
final class GateRow {
  /// Creates a row.
  const GateRow({
    required this.name,
    required this.status,
    this.detail = '',
  });

  /// Gate name.
  final String name;

  /// passed, failed, skipped or waived.
  final String status;

  /// Failure text or waiver reason.
  final String detail;
}

/// Evaluates [outcomes]. A skipped gate fails unless it is waived.
List<GateRow> evaluateGates({
  required Map<String, String> outcomes,
  Map<String, String> waivers = const <String, String>{},
}) {
  return <GateRow>[
    for (final MapEntry<String, String> entry in outcomes.entries)
      if (waivers.containsKey(entry.key))
        GateRow(
          name: entry.key,
          status: 'waived',
          detail: waivers[entry.key] ?? '',
        )
      else if (entry.value == 'passed')
        GateRow(name: entry.key, status: 'passed')
      else if (entry.value == 'skipped')
        GateRow(
          name: entry.key,
          status: 'failed',
          detail: 'skipped gates fail unless waived',
        )
      else
        GateRow(name: entry.key, status: 'failed', detail: entry.value),
  ];
}

/// Writes the gate table beside the artefact. Returns 0 only when every row passes or is waived.
int writeReleaseRecord({
  required String tag,
  required List<GateRow> rows,
  required Directory out,
}) {
  out.createSync(recursive: true);
  final StringBuffer buffer = StringBuffer('# Release $tag\n\n');
  buffer.writeln('| Gate | Status | Detail |');
  buffer.writeln('| --- | --- | --- |');
  var failed = false;
  for (final GateRow row in rows) {
    buffer.writeln('| ${row.name} | ${row.status} | ${row.detail} |');
    if (row.status == 'failed') failed = true;
  }
  File('${out.path}/release-record-$tag.md').writeAsStringSync(buffer.toString());
  return failed ? 1 : 0;
}

/// The gates a release runs for the app, the backend and the pair.
const List<String> releaseGates = <String>[
  'app-verify',
  'secret-scan',
  'app-migration',
  'offline-e2e',
  'export-reader',
  'permission-diff',
  'backend-verify',
  'backend-migration',
  'backend-contract',
  'provider-key-scan',
  'signin-proxy-offline',
];

Future<int> main(List<String> args) async {
  final String? tag = _flag(args, '--tag');
  if (tag == null || tag.isEmpty) {
    stderr.writeln('usage: dart run tool/release_gate.dart --tag <version>');
    return 1;
  }
  final Map<String, String> waivers = <String, String>{};
  for (var index = 0; index < args.length; index++) {
    if (args[index] == '--waive' &&
        index + 3 < args.length &&
        args[index + 2] == '--because') {
      waivers[args[index + 1]] = args[index + 3];
    }
  }
  final Map<String, String> outcomes = <String, String>{
    for (final String gate in releaseGates) gate: 'skipped',
  };
  final int code = writeReleaseRecord(
    tag: tag,
    rows: evaluateGates(outcomes: outcomes, waivers: waivers),
    out: Directory('build'),
  );
  stdout.writeln(File('build/release-record-$tag.md').readAsStringSync());
  return code;
}

String? _flag(List<String> args, String name) {
  final int index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}

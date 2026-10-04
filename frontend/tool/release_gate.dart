import 'dart:io';
import 'dart:isolate';

import 'speech_models.dart' show checkSpeechModels;
import 'whisper_vendor.dart' show checkWhisperVendor, whisperPackage;
import 'whisper_wasm.dart' show checkWhisperWasm;

/// One row of the release record.
final class GateRow {
  /// Creates a row.
  const GateRow({required this.name, required this.status, this.detail = ''});

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
  File(
    '${out.path}/release-record-$tag.md',
  ).writeAsStringSync(buffer.toString());
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
  'speech-assets',
];

/// The package licence the speech engine ships under, relative to
/// `frontend/`.
const String _speechLicence = '$whisperPackage/LICENSE';

/// The first line of each block [_speechLicence] must hold, in order
/// (app-write-up §30.4.1): the shim, whisper.cpp and ggml, the Whisper
/// weights and Silero VAD.
const List<String> _speechLicenceBlocks = <String>[
  'tapture_whisper',
  'whisper.cpp',
  'OpenAI Whisper model weights',
  'Silero VAD',
];

/// Evaluates the `speech-assets` gate over the tree at [frontendRoot]
/// without the network and without writing (dev-plan task 130): every
/// bundled model at its catalogue size and SHA-256, the vendored
/// whisper.cpp and its patch hashes, the WebAssembly `BUILD_INFO.json`, and
/// the four-block package licence. Returns `'passed'`, or one failure text
/// naming every problem found. The hashing checks run in parallel isolates.
Future<String> speechAssetsOutcome(Directory frontendRoot) async {
  final List<List<String>> found = await Future.wait(<Future<List<String>>>[
    Isolate.run(() => checkSpeechModels(frontendRoot)),
    Isolate.run(() => checkWhisperVendor(frontendRoot)),
    Isolate.run(() => checkWhisperWasm(frontendRoot)),
  ]);
  final List<String> problems = <String>[
    for (final List<String> check in found) ...check,
    ..._licenceProblems(frontendRoot),
  ];
  if (problems.isEmpty) return 'passed';
  return '${problems.length} problem(s): ${problems.join('; ')}';
}

/// Every way [_speechLicence] differs from its four blocks in Flutter's
/// 80-dash format: a block missing, out of order, extra or empty.
List<String> _licenceProblems(Directory frontendRoot) {
  final File licence = File('${frontendRoot.path}/$_speechLicence');
  if (!licence.existsSync()) {
    return <String>['$_speechLicence:0: missing'];
  }
  final List<String> lines = licence.readAsLinesSync();
  final List<({int line, List<String> body})> blocks =
      <({int line, List<String> body})>[(line: 1, body: <String>[])];
  for (var index = 0; index < lines.length; index++) {
    if (lines[index] == '-' * 80) {
      blocks.add((line: index + 2, body: <String>[]));
    } else {
      blocks.last.body.add(lines[index]);
    }
  }
  final List<String> headings = <String>[
    for (final ({int line, List<String> body}) block in blocks)
      block.body.isEmpty ? '' : block.body.first.trim(),
  ];
  final List<String> problems = <String>[
    for (final String expected in _speechLicenceBlocks)
      if (!headings.contains(expected))
        '$_speechLicence:0: the $expected block is missing',
  ];
  for (var index = 0; index < blocks.length; index++) {
    final ({int line, List<String> body}) block = blocks[index];
    final String heading = headings[index];
    final String name = _speechLicenceBlocks.contains(heading)
        ? 'the $heading block'
        : 'block ${index + 1}';
    if (!_speechLicenceBlocks.contains(heading)) {
      problems.add(
        '$_speechLicence:${block.line}: $name is not one of '
        '${_speechLicenceBlocks.join(', ')}',
      );
    }
    if (block.body.skip(1).every((String line) => line.trim().isEmpty)) {
      problems.add('$_speechLicence:${block.line}: $name has no licence text');
    }
  }
  if (problems.isEmpty &&
      headings.join(', ') != _speechLicenceBlocks.join(', ')) {
    problems.add(
      '$_speechLicence:1: the blocks are ${headings.join(', ')}; expected '
      '${_speechLicenceBlocks.join(', ')} in that order',
    );
  }
  return problems;
}

Future<int> main(List<String> args) async {
  final String? tag = _flag(args, '--tag');
  if (tag == null || tag.isEmpty) {
    stderr.writeln('usage: dart run tool/release_gate.dart --tag <version>');
    exitCode = 64;
    return exitCode;
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
    'speech-assets': await speechAssetsOutcome(Directory.current),
  };
  final int code = writeReleaseRecord(
    tag: tag,
    rows: evaluateGates(outcomes: outcomes, waivers: waivers),
    out: Directory('build'),
  );
  stdout.writeln(File('build/release-record-$tag.md').readAsStringSync());
  // The VM ignores main's return value; only exitCode reaches the shell.
  exitCode = code;
  return code;
}

String? _flag(List<String> args, String name) {
  final int index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}

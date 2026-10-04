import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/constants/speech_assets.dart';
import 'package:tapture/core/speech/speech_model_catalogue.dart';
import 'package:tapture/core/speech/speech_model_entry.dart';
import 'package:tapture/core/speech/speech_model_header.dart';

/// Opens the byte stream behind a pinned model URL. The only network seam:
/// `--check` and `--verify` never call it, and `--from` replaces it.
typedef SpeechModelFetcher = Future<Stream<List<int>>> Function(Uri source);

const String _usage =
    'usage: dart run tool/speech_models.dart '
    '--fetch [--only <id>] [--from <dir>] | --check | --verify <file> | '
    '--import-model <id> --out <dir> [--from <dir>]';

/// How long the default fetcher waits for a connection before reporting it.
const Duration _connectTimeout = Duration(seconds: 30);

/// Fetches, checks and verifies the speech models by size and SHA-256
/// (dev-plan task 101), printing one `path:0: problem` line per violation.
///
/// Run from `frontend/`.
Future<void> main(List<String> args) async {
  exitCode = await runSpeechModels(args, root: Directory.current);
}

/// Runs one command against the tree at [root] and returns the exit code:
/// 0 when clean, 1 when any problem was printed, 64 for bad arguments.
///
/// [fetch] opens a pinned URL; [catalogue] defaults to every catalogue
/// entry. Problems go to [problems] and progress to [progress], defaulting
/// to stderr and stdout.
Future<int> runSpeechModels(
  List<String> args, {
  required Directory root,
  SpeechModelFetcher fetch = _download,
  List<SpeechModelEntry> catalogue = SpeechModelCatalogue.all,
  StringSink? problems,
  StringSink? progress,
}) async {
  final StringSink problemSink = problems ?? stderr;
  final StringSink progressSink = progress ?? stdout;
  final _Arguments? parsed = _Arguments.parse(args);
  if (parsed == null) {
    problemSink.writeln(_usage);
    return 64;
  }
  final _Run run = _Run(
    root: root,
    fetch: fetch,
    catalogue: catalogue,
    progress: progressSink,
  );
  final List<String> found = switch (parsed.command) {
    '--fetch' => await run.fetchBundled(only: parsed.only, from: parsed.from),
    '--check' => checkSpeechModels(root, catalogue: catalogue),
    '--verify' => run.verify(parsed.operand!),
    _ => await run.importModel(
      parsed.operand!,
      out: parsed.out!,
      from: parsed.from,
    ),
  };
  for (final String problem in found) {
    problemSink.writeln(problem);
  }
  progressSink.writeln(
    found.isEmpty
        ? 'speech models: clean'
        : 'speech models: ${found.length} problem(s)',
  );
  return found.isEmpty ? 0 : 1;
}

/// Checks the bundled speech models under [frontendRoot] without the
/// network and without writing: every bundled file is present at its exact
/// size and SHA-256, no `.part` is left over, and `manifest.json` equals
/// the one the catalogue generates. Returns one `path:0: problem` per
/// violation.
List<String> checkSpeechModels(
  Directory frontendRoot, {
  List<SpeechModelEntry> catalogue = SpeechModelCatalogue.all,
}) {
  final List<String> problems = <String>[];
  for (final SpeechModelEntry entry in _bundled(catalogue)) {
    final String asset = entry.asset!;
    final File file = File('${frontendRoot.path}/$asset');
    if (file.existsSync()) {
      problems.addAll(_contentProblems(asset, file, entry));
    } else {
      problems.add(
        '$asset:0: missing; run dart run tool/speech_models.dart --fetch',
      );
    }
    if (File('${file.path}.part').existsSync()) {
      problems.add('$asset.part:0: an unfinished download is left over');
    }
  }
  final File manifest = File('${frontendRoot.path}/${SpeechAssets.manifest}');
  if (!manifest.existsSync()) {
    problems.add('${SpeechAssets.manifest}:0: missing; run --fetch');
  } else if (manifest.readAsStringSync().replaceAll('\r\n', '\n') !=
      _manifestFor(catalogue)) {
    problems.add(
      '${SpeechAssets.manifest}:0: differs from the catalogue; run --fetch',
    );
  }
  return problems;
}

/// The deterministic `manifest.json` for the bundled entries of
/// [catalogue], sorted by id, with a trailing newline.
String _manifestFor(List<SpeechModelEntry> catalogue) {
  final List<SpeechModelEntry> bundled = _bundled(catalogue).toList()
    ..sort((SpeechModelEntry a, SpeechModelEntry b) => a.id.compareTo(b.id));
  final Map<String, Object> manifest = <String, Object>{
    'generatedBy': 'tool/speech_models.dart',
    'models': <Map<String, Object>>[
      for (final SpeechModelEntry entry in bundled)
        <String, Object>{
          'id': entry.id,
          'kind': entry.kind.name,
          'asset': entry.asset!,
          'bytes': entry.bytes,
          'sha256': entry.sha256,
          'source': entry.sourceUrl,
        },
    ],
  };
  return '${const JsonEncoder.withIndent('  ').convert(manifest)}\n';
}

Iterable<SpeechModelEntry> _bundled(List<SpeechModelEntry> catalogue) =>
    catalogue.where((SpeechModelEntry entry) => entry.asset != null);

/// Size, then SHA-256, of [file] against [entry].
List<String> _contentProblems(
  String display,
  File file,
  SpeechModelEntry entry,
) {
  final int length = file.lengthSync();
  if (length != entry.bytes) {
    return <String>[
      '$display:0: $length bytes, the catalogue pins ${entry.bytes}',
    ];
  }
  final String digest = _sha256OfFileSync(file);
  if (digest != entry.sha256) {
    return <String>[
      '$display:0: sha256 $digest, the catalogue pins ${entry.sha256}',
    ];
  }
  return const <String>[];
}

String _sha256OfFileSync(File file) {
  final _DigestSink output = _DigestSink();
  final ByteConversionSink sink = sha256.startChunkedConversion(output);
  final RandomAccessFile handle = file.openSync();
  final Uint8List buffer = Uint8List(1 << 20);
  try {
    for (
      int read = handle.readIntoSync(buffer);
      read > 0;
      read = handle.readIntoSync(buffer)
    ) {
      sink.add(Uint8List.sublistView(buffer, 0, read));
    }
  } finally {
    handle.closeSync();
  }
  sink.close();
  return output.value.toString();
}

/// One command's state: where it writes and where bytes come from.
final class _Run {
  _Run({
    required this.root,
    required this.fetch,
    required this.catalogue,
    required this.progress,
  });

  final Directory root;
  final SpeechModelFetcher fetch;
  final List<SpeechModelEntry> catalogue;
  final StringSink progress;

  Future<List<String>> fetchBundled({String? only, String? from}) async {
    final List<SpeechModelEntry> targets = _bundled(catalogue)
        .where((SpeechModelEntry entry) => only == null || entry.id == only)
        .toList();
    if (targets.isEmpty) {
      return <String>[
        'tool/speech_models.dart:0: --only $only names no bundled model',
      ];
    }
    final List<String> problems = <String>[];
    for (final SpeechModelEntry entry in targets) {
      problems.addAll(
        await _install(entry, entry.asset!, _resolve(entry.asset!), from),
      );
    }
    final File manifest = _resolve(SpeechAssets.manifest);
    final String expected = _manifestFor(catalogue);
    if (!manifest.existsSync() ||
        manifest.readAsStringSync().replaceAll('\r\n', '\n') != expected) {
      manifest.parent.createSync(recursive: true);
      manifest.writeAsStringSync(expected, flush: true);
      progress.writeln('wrote ${SpeechAssets.manifest}');
    }
    return problems;
  }

  Future<List<String>> importModel(
    String id, {
    required String out,
    String? from,
  }) async {
    final SpeechModelEntry? entry = _byId(id);
    if (entry == null) {
      return <String>[
        'tool/speech_models.dart:0: --import-model $id names no model',
      ];
    }
    final String display = '$out/${entry.fileName}';
    return _install(entry, display, _resolve(display), from);
  }

  List<String> verify(String path) {
    final File file = _resolve(path);
    if (!file.existsSync()) {
      return <String>['$path:0: missing'];
    }
    final int length = file.lengthSync();
    final String digest = _sha256OfFileSync(file);
    final String name = file.uri.pathSegments.last;
    final SpeechModelEntry? entry =
        _byFileName(name) ?? _byContent(length, digest);
    if (entry == null) {
      return <String>[
        '$path:0: no catalogue model has $length bytes and sha256 $digest',
      ];
    }
    final List<String> problems = <String>[
      if (length != entry.bytes)
        '$path:0: $length bytes, ${entry.id} pins ${entry.bytes}'
      else if (digest != entry.sha256)
        '$path:0: sha256 $digest, ${entry.id} pins ${entry.sha256}',
      ..._headerProblems(path, file, entry),
    ];
    if (problems.isEmpty) {
      progress.writeln('$path: ${entry.id}, size, header and sha256 match');
    }
    return problems;
  }

  List<String> _headerProblems(String path, File file, SpeechModelEntry entry) {
    final RandomAccessFile handle = file.openSync();
    final Uint8List first;
    try {
      first = handle.readSync(SpeechModelHeader.length);
    } finally {
      handle.closeSync();
    }
    final SpeechModelHeader? header = SpeechModelHeader.parse(first);
    if (header == null) {
      return <String>['$path:0: shorter than the model header'];
    }
    final List<String> fields = header.mismatchesWith(entry);
    return <String>[
      if (fields.isNotEmpty)
        '$path:0: header ${fields.join(', ')} disagree with ${entry.id}',
    ];
  }

  /// Brings [target] to [entry]'s exact bytes, streaming through
  /// `<target>.part` and hashing while it writes, then renaming. A target
  /// already correct is kept as it is.
  Future<List<String>> _install(
    SpeechModelEntry entry,
    String display,
    File target,
    String? from,
  ) async {
    if (target.existsSync() &&
        _contentProblems(display, target, entry).isEmpty) {
      progress.writeln('$display: already verified');
      return const <String>[];
    }
    target.parent.createSync(recursive: true);
    final File part = File('${target.path}.part');
    final String source = from == null
        ? entry.sourceUrl
        : '$from/${entry.fileName}';
    if (from != null && !_resolve(source).existsSync()) {
      return <String>['$display:0: the mirror has no $source'];
    }
    try {
      final Stream<List<int>> bytes = from == null
          ? await fetch(Uri.parse(entry.sourceUrl))
          : _resolve(source).openRead();
      final String? problem = await _streamInto(part, bytes, entry);
      if (problem != null) {
        await _discard(part);
        return <String>['$display:0: $problem from $source'];
      }
      await part.rename(target.path);
      progress.writeln('$display: fetched ${entry.bytes} bytes');
      return const <String>[];
    } on IOException catch (error) {
      await _discard(part);
      final String reason = switch (error) {
        FileSystemException(:final String message, :final OSError? osError) =>
          osError?.message ?? message,
        _ => '$error',
      };
      return <String>['$display:0: could not read $source: $reason'];
    }
  }

  /// Writes [bytes] to [part], hashing as it goes, and stops at the first
  /// byte past [entry]'s size. Returns the problem, or null on a match.
  Future<String?> _streamInto(
    File part,
    Stream<List<int>> bytes,
    SpeechModelEntry entry,
  ) async {
    final _DigestSink output = _DigestSink();
    final ByteConversionSink hasher = sha256.startChunkedConversion(output);
    final IOSink sink = part.openWrite();
    int written = 0;
    try {
      await for (final List<int> chunk in bytes) {
        written += chunk.length;
        if (written > entry.bytes) {
          break;
        }
        hasher.add(chunk);
        sink.add(chunk);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    if (written > entry.bytes) {
      return 'received more than the ${entry.bytes} bytes pinned';
    }
    if (written < entry.bytes) {
      return 'received only $written of ${entry.bytes} bytes';
    }
    hasher.close();
    final String digest = output.value.toString();
    return digest == entry.sha256
        ? null
        : 'sha256 $digest, the catalogue pins ${entry.sha256}';
  }

  Future<void> _discard(File part) async {
    if (part.existsSync()) {
      await part.delete();
    }
  }

  File _resolve(String path) =>
      File(File(path).isAbsolute ? path : '${root.path}/$path');

  SpeechModelEntry? _byId(String id) {
    for (final SpeechModelEntry entry in catalogue) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  SpeechModelEntry? _byFileName(String name) {
    for (final SpeechModelEntry entry in catalogue) {
      if (entry.fileName == name) {
        return entry;
      }
    }
    return null;
  }

  SpeechModelEntry? _byContent(int bytes, String digest) {
    for (final SpeechModelEntry entry in catalogue) {
      if (entry.bytes == bytes && entry.sha256 == digest) {
        return entry;
      }
    }
    return null;
  }
}

/// The parsed command line: one command, its operand and its options.
final class _Arguments {
  const _Arguments(
    this.command, {
    this.operand,
    this.only,
    this.from,
    this.out,
  });

  final String command;
  final String? operand;
  final String? only;
  final String? from;
  final String? out;

  static const Set<String> _commands = <String>{
    '--fetch',
    '--check',
    '--verify',
    '--import-model',
  };

  static _Arguments? parse(List<String> args) {
    final Map<String, String?> values = <String, String?>{};
    for (int index = 0; index < args.length; index++) {
      final String flag = args[index];
      final bool takesValue = flag != '--fetch' && flag != '--check';
      if (values.containsKey(flag) ||
          !(_commands.contains(flag) ||
              const <String>{'--only', '--from', '--out'}.contains(flag))) {
        return null;
      }
      if (takesValue) {
        if (index + 1 >= args.length || args[index + 1].startsWith('--')) {
          return null;
        }
        values[flag] = args[++index];
      } else {
        values[flag] = null;
      }
    }
    final List<String> commands = values.keys
        .where(_commands.contains)
        .toList();
    if (commands.length != 1) {
      return null;
    }
    final String command = commands.single;
    final Set<String> allowed = switch (command) {
      '--fetch' => const <String>{'--fetch', '--only', '--from'},
      '--check' => const <String>{'--check'},
      '--verify' => const <String>{'--verify'},
      _ => const <String>{'--import-model', '--out', '--from'},
    };
    if (!values.keys.every(allowed.contains) ||
        (command == '--import-model' && !values.containsKey('--out'))) {
      return null;
    }
    return _Arguments(
      command,
      operand: values[command],
      only: values['--only'],
      from: values['--from'],
      out: values['--out'],
    );
  }
}

final class _DigestSink implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value!;

  @override
  void add(Digest data) {
    _value = data;
  }

  @override
  void close() {}
}

Future<Stream<List<int>>> _download(Uri source) async {
  final HttpClient client = HttpClient()..connectionTimeout = _connectTimeout;
  try {
    final HttpClientRequest request = await client.getUrl(source);
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException('HTTP ${response.statusCode}', uri: source);
    }
    return response;
  } finally {
    client.close();
  }
}

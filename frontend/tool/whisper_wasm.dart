import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'whisper_vendor.dart' show whisperPackage;

/// Where the committed WebAssembly engine lives, relative to `frontend/`.
const String whisperWasmDirectory = 'web/whisper';

/// The two variants: single-threaded, and pthreads for cross-origin-isolated
/// pages (app-write-up §30.4.8).
const List<String> whisperWasmVariants = <String>['st', 'mt'];

/// The build record beside the artifacts.
const String whisperWasmRecord = '$whisperWasmDirectory/BUILD_INFO.json';

/// The licences of everything the artifacts contain.
const String whisperWasmLicences = '$whisperWasmDirectory/LICENSES.txt';

/// The hand-written worker whose struct and status tables `--check` compares
/// with the header.
const String whisperWasmWorker = '$whisperWasmDirectory/whisper_worker.js';

/// The file pinning the one Emscripten release `--build` accepts.
const String emsdkVersionFile = '$whisperPackage/wasm/emsdk_version.txt';

const String _header = '$whisperPackage/src/tapture_whisper.h';
const String _exports = '$whisperPackage/src/wasm_exports.txt';
const String _vendorRecord = '$whisperPackage/VENDOR.json';
const String _smoke = '$whisperPackage/wasm/smoke.mjs';

const String _usage =
    'usage: dart run tool/whisper_wasm.dart --build [--smoke] | --check | '
    '--smoke';

/// Reads `emcc --version` with the environment the build runs in, or returns
/// null when emcc cannot be run.
typedef EmccVersionProbe =
    Future<String?> Function(Map<String, String> environment);

/// Builds, checks or smoke-tests the WebAssembly speech engine (dev-plan task
/// 111, app-write-up §30.4.8), printing one `path:line: message` per
/// violation. Run from `frontend/`, with the pinned emsdk's environment for
/// `--build`.
Future<void> main(List<String> args) async {
  exitCode = await runWhisperWasm(args, root: Directory.current);
}

/// Runs one command against the `frontend/` tree at [root] and returns the
/// exit code: 0 when clean, 1 on any violation or failed step, 64 for bad
/// arguments. [environment] defaults to the process environment and
/// [emccVersion] to running the emsdk's emcc; both are seams for tests.
Future<int> runWhisperWasm(
  List<String> args, {
  required Directory root,
  Map<String, String>? environment,
  EmccVersionProbe? emccVersion,
  StringSink? problems,
  StringSink? progress,
}) async {
  final StringSink problemSink = problems ?? stderr;
  final StringSink progressSink = progress ?? stdout;
  final Set<String> flags = args.toSet();
  final bool build = flags.contains('--build');
  final bool check = flags.contains('--check');
  final bool smoke = flags.contains('--smoke');
  final bool valid =
      flags.length == args.length &&
      flags.difference(<String>{'--build', '--check', '--smoke'}).isEmpty &&
      (build ? !check : (check != smoke));
  if (!valid) {
    problemSink.writeln(_usage);
    return 64;
  }
  final Map<String, String> env = environment ?? Platform.environment;
  final List<String> found = <String>[];
  if (build) {
    found.addAll(
      await buildWhisperWasm(
        root,
        environment: env,
        emccVersion: emccVersion ?? _probeEmcc,
        progress: progressSink,
      ),
    );
    if (found.isEmpty) {
      found.addAll(checkWhisperWasm(root));
    }
  } else if (check) {
    found.addAll(checkWhisperWasm(root));
  }
  if (smoke && found.isEmpty) {
    found.addAll(await smokeWhisperWasm(root, environment: env));
  }
  for (final String problem in found) {
    problemSink.writeln(problem);
  }
  progressSink.writeln(
    found.isEmpty
        ? 'whisper wasm: clean'
        : 'whisper wasm: ${found.length} violation(s)',
  );
  return found.isEmpty ? 0 : 1;
}

/// Builds both variants with the pinned emsdk into `build/tw-wasm-<variant>`,
/// copies them into [whisperWasmDirectory] and writes [whisperWasmLicences]
/// and [whisperWasmRecord]. Nothing is built unless `$EMSDK` is set and its
/// emcc is exactly the version in [emsdkVersionFile]. Returns one
/// `path:line: message` per problem.
Future<List<String>> buildWhisperWasm(
  Directory root, {
  required Map<String, String> environment,
  required EmccVersionProbe emccVersion,
  required StringSink progress,
}) async {
  final String? pinned = _pinnedEmsdk(root);
  if (pinned == null) {
    return <String>['$emsdkVersionFile:1: missing or not a version (x.y.z)'];
  }
  final String? emsdk = environment['EMSDK'];
  if (emsdk == null || emsdk.isEmpty) {
    return <String>[
      '$emsdkVersionFile:1: EMSDK is not set; activate emsdk $pinned '
          '(source emsdk_env) first',
    ];
  }
  final String? version = _emccVersion(await emccVersion(environment));
  if (version != pinned) {
    return <String>[
      '$emsdkVersionFile:1: emcc is ${version ?? 'not runnable'}, not the '
          'pinned $pinned; activate emsdk $pinned',
    ];
  }
  final String? cmake = _findTool('cmake', environment['CMAKE'], environment);
  final String? ninja = _findTool('ninja', environment['NINJA'], environment);
  if (cmake == null || ninja == null) {
    return <String>[
      '$emsdkVersionFile:1: ${cmake == null ? 'cmake' : 'ninja'} not found '
          '(set CMAKE or NINJA, or install the Android SDK CMake)',
    ];
  }
  final String toolchain =
      '$emsdk/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake';
  final Map<String, String> flags = <String, String>{};
  for (final String variant in whisperWasmVariants) {
    final String buildDir = 'build/tw-wasm-$variant';
    progress.writeln('whisper wasm: building $variant in $buildDir');
    final List<List<String>> steps = <List<String>>[
      <String>[
        '-S',
        '$whisperPackage/src',
        '-B',
        buildDir,
        '-G',
        'Ninja',
        '-DCMAKE_MAKE_PROGRAM=$ninja',
        '-DCMAKE_TOOLCHAIN_FILE=$toolchain',
        '-DCMAKE_BUILD_TYPE=Release',
        '-DTW_WASM_THREADS=${variant == 'mt' ? 'ON' : 'OFF'}',
      ],
      <String>['--build', buildDir],
    ];
    for (final List<String> step in steps) {
      final int code = await _run(cmake, step, root, environment);
      if (code != 0) {
        return <String>[
          '$whisperPackage/src/CMakeLists.txt:1: $variant: '
              'cmake ${step.first} exited $code',
        ];
      }
    }
    for (final String extension in <String>['js', 'wasm']) {
      final String name = 'tapture_whisper_$variant.$extension';
      File(
        '${root.path}/$buildDir/$name',
      ).copySync('${root.path}/$whisperWasmDirectory/$name');
    }
    flags[variant] = File(
      '${root.path}/$buildDir/tw_wasm_flags.txt',
    ).readAsStringSync().trim();
  }
  File(
    '${root.path}/$whisperWasmLicences',
  ).writeAsStringSync(whisperWasmLicenceText(root, Directory(emsdk)));
  writeWhisperWasmRecord(root, emsdk: pinned, flags: flags);
  progress.writeln('whisper wasm: built with emsdk $pinned');
  return <String>[];
}

/// The licences of the shipped artifacts: the package's own four blocks,
/// then Emscripten, musl and the LLVM runtime libraries from [emsdk], in
/// Flutter's 80-dash format. Identical LLVM texts are written once.
String whisperWasmLicenceText(Directory root, Directory emsdk) {
  final String base = '${emsdk.path}/upstream/emscripten';
  final List<({List<String> names, String path})> blocks =
      <({List<String> names, String path})>[
        (names: <String>['emscripten'], path: '$base/LICENSE'),
        (names: <String>['musl'], path: '$base/system/lib/libc/musl/COPYRIGHT'),
        (
          names: <String>['libc++', 'libc++abi', 'libunwind'],
          path: '$base/system/lib/libcxx/LICENSE.TXT',
        ),
        (
          names: <String>['compiler-rt'],
          path: '$base/system/lib/compiler-rt/LICENSE.TXT',
        ),
      ];
  final StringBuffer text = StringBuffer(
    _lf(
      File('${root.path}/$whisperPackage/LICENSE').readAsStringSync(),
    ).trimRight(),
  );
  final Map<String, List<String>> byText = <String, List<String>>{};
  for (final ({List<String> names, String path}) block in blocks) {
    final String licence = _lf(File(block.path).readAsStringSync()).trim();
    byText.putIfAbsent(licence, () => <String>[]).addAll(block.names);
  }
  for (final MapEntry<String, List<String>> entry in byText.entries) {
    text
      ..write('\n${'-' * 80}\n')
      ..write(entry.value.join('\n'))
      ..write('\n\n')
      ..write(entry.key);
  }
  text.write('\n');
  return text.toString();
}

/// Writes [whisperWasmRecord] for the tree at [root] as it is now: the ABI,
/// the vendored whisper.cpp and its patches, the emsdk version, the link
/// [flags] of each variant, and the SHA-256 of every build input and output.
void writeWhisperWasmRecord(
  Directory root, {
  required String emsdk,
  required Map<String, String> flags,
}) {
  final Map<String, Object?> vendor = _json(root, _vendorRecord) ?? {};
  final Map<String, Object?> record = <String, Object?>{
    'abi': _headerFacts(root)?.abi,
    'whisper': vendor['tag'],
    'commit': vendor['commit'],
    'patches': <Object?>[
      for (final Object? patch in (vendor['patches'] as List<Object?>?) ?? [])
        if (patch is Map<String, Object?>)
          <String, Object?>{'name': patch['name'], 'sha256': patch['sha256']},
    ],
    'emsdk': emsdk,
    'flags': flags,
    'inputs': <String, String>{
      for (final String path in whisperWasmInputs(root))
        path: _digest(root, path),
    },
    'files': <String, String>{
      for (final String name in whisperWasmOutputs)
        name: _digest(root, '$whisperWasmDirectory/$name'),
    },
  };
  File('${root.path}/$whisperWasmRecord').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );
}

/// The artifacts [whisperWasmRecord] pins, by name within
/// [whisperWasmDirectory].
const List<String> whisperWasmOutputs = <String>[
  'tapture_whisper_st.js',
  'tapture_whisper_st.wasm',
  'tapture_whisper_mt.js',
  'tapture_whisper_mt.wasm',
  'LICENSES.txt',
];

/// Every file the artifacts are built from, relative to `frontend/`: the
/// package's licence, vendor record and pinned emsdk version, everything in
/// its `src/` but the native smoke tool, and every vendored file but the
/// sample audio and test models.
List<String> whisperWasmInputs(Directory root) {
  final List<String> inputs = <String>[
    '$whisperPackage/LICENSE',
    _vendorRecord,
    emsdkVersionFile,
  ];
  final Directory src = Directory('${root.path}/$whisperPackage/src');
  if (src.existsSync()) {
    for (final FileSystemEntity entity in src.listSync(recursive: true)) {
      final String path = _relative(root, entity.path);
      if (entity is File && !path.startsWith('$whisperPackage/src/smoke/')) {
        inputs.add(path);
      }
    }
  }
  final Object? files = _json(root, _vendorRecord)?['files'];
  if (files is Map<String, Object?>) {
    for (final String path in files.keys) {
      if (!path.startsWith('samples/') && !path.startsWith('models/')) {
        inputs.add('$whisperPackage/third_party/whisper.cpp/$path');
      }
    }
  }
  return inputs..sort();
}

/// Checks the committed engine against the tree at [root] without emsdk:
/// [whisperWasmRecord]'s ABI, emsdk version, inputs and outputs; that
/// `src/wasm_exports.txt` is exactly the header's `TW_API` names; that each
/// glue file exports every one of them; and that the worker's struct and
/// status tables equal the header. Returns one `path:line: message` per
/// violation, all of them.
List<String> checkWhisperWasm(Directory root) {
  final List<String> found = <String>[];
  final _HeaderFacts? header = _headerFacts(root);
  if (header == null) {
    return <String>['$_header:1: missing or without TW_ABI_VERSION'];
  }
  found
    ..addAll(_recordProblems(root, header))
    ..addAll(_exportProblems(root, header))
    ..addAll(_workerProblems(root, header));
  return found;
}

/// Runs `packages/tapture_whisper/wasm/smoke.mjs` under Node for both
/// variants: `$EMSDK_NODE` when set, else `node` on PATH. Returns one line
/// per failed variant.
Future<List<String>> smokeWhisperWasm(
  Directory root, {
  required Map<String, String> environment,
}) async {
  final String node = environment['EMSDK_NODE'] ?? 'node';
  final List<String> found = <String>[];
  for (final String variant in whisperWasmVariants) {
    final int code = await _run(
      node,
      <String>[_smoke, '--variant', variant],
      root,
      environment,
    );
    if (code != 0) {
      found.add('$_smoke:1: $variant smoke exited $code');
    }
  }
  return found;
}

List<String> _recordProblems(Directory root, _HeaderFacts header) {
  final File file = File('${root.path}/$whisperWasmRecord');
  final Map<String, Object?>? record = _json(root, whisperWasmRecord);
  if (record == null) {
    return <String>['$whisperWasmRecord:1: missing or not a JSON object'];
  }
  final List<String> lines = file.readAsLinesSync();
  int lineOf(String key) {
    final int index = lines.indexWhere((String l) => l.contains('"$key"'));
    return index < 0 ? 1 : index + 1;
  }

  final List<String> found = <String>[];
  if (record['abi'] != header.abi) {
    found.add(
      '$whisperWasmRecord:${lineOf('abi')}: abi ${record['abi']}; '
      '$_header has TW_ABI_VERSION ${header.abi}. Rebuild with --build',
    );
  }
  final String? pinned = _pinnedEmsdk(root);
  if (record['emsdk'] != pinned) {
    found.add(
      '$whisperWasmRecord:${lineOf('emsdk')}: emsdk ${record['emsdk']}; '
      '$emsdkVersionFile pins $pinned. Rebuild with --build',
    );
  }
  final Map<String, Object?> inputs = _map(record['inputs']);
  final List<String> expected = whisperWasmInputs(root);
  for (final String path in expected) {
    final Object? digest = inputs[path];
    final File input = File('${root.path}/$path');
    if (!input.existsSync()) {
      found.add('$path:1: build input missing');
    } else if (digest == null) {
      found.add(
        '$path:1: a build input $whisperWasmRecord does not record. '
        'Rebuild with --build',
      );
    } else if (_digest(root, path) != digest) {
      found.add(
        '$path:1: sha256 ${_digest(root, path)}; '
        '$whisperWasmRecord:${lineOf(path)} records $digest. The engine was '
        'built from other sources; rebuild with --build',
      );
    }
  }
  for (final String path in inputs.keys) {
    if (!expected.contains(path)) {
      found.add(
        '$whisperWasmRecord:${lineOf(path)}: records $path, which is no '
        'longer a build input. Rebuild with --build',
      );
    }
  }
  final Map<String, Object?> files = _map(record['files']);
  for (final String name in whisperWasmOutputs) {
    final String path = '$whisperWasmDirectory/$name';
    final Object? digest = files[name];
    if (!File('${root.path}/$path').existsSync()) {
      found.add('$path:1: artifact missing. Rebuild with --build');
    } else if (digest == null) {
      found.add('$whisperWasmRecord:1: records no sha256 for $name');
    } else if (_digest(root, path) != digest) {
      found.add(
        '$path:1: sha256 ${_digest(root, path)}; '
        '$whisperWasmRecord:${lineOf(name)} records $digest. The artifact '
        'was changed after the build; rebuild with --build',
      );
    }
  }
  return found;
}

List<String> _exportProblems(Directory root, _HeaderFacts header) {
  final File file = File('${root.path}/$_exports');
  if (!file.existsSync()) {
    return <String>['$_exports:1: missing'];
  }
  final List<String> found = <String>[];
  final List<String> lines = file.readAsLinesSync();
  final List<String> listed = <String>[];
  for (int i = 0; i < lines.length; i++) {
    final String line = lines[i].trim();
    if (line.isEmpty) {
      found.add('$_exports:${i + 1}: blank line (emcc reads it as a symbol)');
    } else if (!line.startsWith('#')) {
      listed.add(line);
      if (!header.api.contains(line.substring(1)) || !line.startsWith('_')) {
        found.add('$_exports:${i + 1}: $line is not a TW_API name of $_header');
      }
    }
  }
  for (final String name in header.api) {
    if (!listed.contains('_$name')) {
      found.add('$_exports:1: _$name, a TW_API name of $_header, is missing');
    }
  }
  for (final String variant in whisperWasmVariants) {
    final String path = '$whisperWasmDirectory/tapture_whisper_$variant.js';
    final File glue = File('${root.path}/$path');
    if (!glue.existsSync()) {
      continue;
    }
    final String text = glue.readAsStringSync();
    for (final String name in header.api) {
      if (!text.contains('Module["_$name"]')) {
        found.add('$path:1: does not export _$name');
      }
    }
  }
  return found;
}

List<String> _workerProblems(Directory root, _HeaderFacts header) {
  final File file = File('${root.path}/$whisperWasmWorker');
  if (!file.existsSync()) {
    return <String>['$whisperWasmWorker:1: missing'];
  }
  final List<String> lines = file.readAsLinesSync();
  final List<String> found = <String>[];
  final _Table? structs = _table(lines, 'tw-struct-table');
  if (structs == null) {
    found.add(
      '$whisperWasmWorker:1: no // tw-struct-table:begin ... :end block',
    );
  } else {
    final RegExp row = RegExp(
      r'^\s*([A-Z_0-9]+):\s*\{\s*id:\s*(\d+),\s*size:\s*(\d+)\s*\},?\s*$',
    );
    final Set<String> seen = <String>{};
    for (int i = structs.first; i < structs.end; i++) {
      final RegExpMatch? match = row.firstMatch(lines[i]);
      if (match == null) {
        continue;
      }
      final String name = match.group(1)!;
      final int id = int.parse(match.group(2)!);
      final int size = int.parse(match.group(3)!);
      seen.add(name);
      final int? headerSize = header.sizes[name];
      if (headerSize == null) {
        found.add(
          '$whisperWasmWorker:${i + 1}: $name has no TW_SIZEOF_$name in '
          '$_header',
        );
        continue;
      }
      if (size != headerSize) {
        found.add(
          '$whisperWasmWorker:${i + 1}: $name size $size; $_header has '
          'TW_SIZEOF_$name $headerSize',
        );
      }
      if (id != header.structIds[name]) {
        found.add(
          '$whisperWasmWorker:${i + 1}: $name id $id; $_header has '
          'TW_STRUCT_$name = ${header.structIds[name]}',
        );
      }
    }
    for (final String name in header.sizes.keys) {
      if (!seen.contains(name)) {
        found.add(
          '$whisperWasmWorker:${structs.first}: $name (TW_SIZEOF_$name) is '
          'missing from the struct table',
        );
      }
    }
  }
  final _Table? statuses = _table(lines, 'tw-status-table');
  if (statuses == null) {
    found.add(
      '$whisperWasmWorker:1: no // tw-status-table:begin ... :end block',
    );
  } else {
    final RegExp row = RegExp(r"^\s*'([a-z_0-9]+)',?\s*$");
    final List<({String name, int line})> listed =
        <({String name, int line})>[];
    for (int i = statuses.first; i < statuses.end; i++) {
      final RegExpMatch? match = row.firstMatch(lines[i]);
      if (match != null) {
        listed.add((name: match.group(1)!, line: i + 1));
      }
    }
    for (int code = 0; code < header.statuses.length; code++) {
      final String expected = header.statuses[code];
      if (code >= listed.length) {
        found.add(
          '$whisperWasmWorker:${statuses.first}: status $code ($expected) '
          'is missing from the status table',
        );
      } else if (listed[code].name != expected) {
        found.add(
          '$whisperWasmWorker:${listed[code].line}: status $code is '
          "'${listed[code].name}'; $_header has '$expected'",
        );
      }
    }
    for (int code = header.statuses.length; code < listed.length; code++) {
      found.add(
        '$whisperWasmWorker:${listed[code].line}: status $code '
        "'${listed[code].name}' is not in $_header",
      );
    }
  }
  return found;
}

/// The lines strictly between `// <marker>:begin` and `// <marker>:end`:
/// [first] is the index after the begin line, [end] the end line's index.
typedef _Table = ({int first, int end});

_Table? _table(List<String> lines, String marker) {
  final int begin = lines.indexWhere(
    (String l) => l.trim() == '// $marker:begin',
  );
  final int end = lines.indexWhere((String l) => l.trim() == '// $marker:end');
  return begin < 0 || end <= begin ? null : (first: begin + 1, end: end);
}

/// What `tapture_whisper.h` publishes that the WebAssembly side depends on.
typedef _HeaderFacts = ({
  int abi,
  Map<String, int> sizes,
  Map<String, int> structIds,
  List<String> statuses,
  List<String> api,
});

_HeaderFacts? _headerFacts(Directory root) {
  final File file = File('${root.path}/$_header');
  if (!file.existsSync()) {
    return null;
  }
  final String text = file.readAsStringSync();
  final RegExpMatch? abi = RegExp(
    r'^#define TW_ABI_VERSION\s+(\d+)',
    multiLine: true,
  ).firstMatch(text);
  if (abi == null) {
    return null;
  }
  final Map<String, int> sizes = <String, int>{
    for (final RegExpMatch m in RegExp(
      r'^#define TW_SIZEOF_([A-Z_0-9]+)\s+(\d+)',
      multiLine: true,
    ).allMatches(text))
      m.group(1)!: int.parse(m.group(2)!),
  };
  final Map<String, int> ids = <String, int>{
    for (final RegExpMatch m in RegExp(
      r'\bTW_STRUCT_([A-Z_0-9]+)\s*=\s*(\d+)',
    ).allMatches(text))
      m.group(1)!: int.parse(m.group(2)!),
  };
  final Map<int, String> statuses = <int, String>{
    for (final RegExpMatch m in RegExp(
      r'\bTW_(OK|ERR_[A-Z_0-9]+)\s*=\s*(\d+)',
    ).allMatches(text))
      int.parse(m.group(2)!): m
          .group(1)!
          .replaceFirst('ERR_', '')
          .toLowerCase(),
  };
  final List<String> api = <String>[
    for (final RegExpMatch m in RegExp(
      r'^TW_API\b[^;(]*?\b(tw_[a-z0-9_]+)\s*\(',
      multiLine: true,
    ).allMatches(text))
      m.group(1)!,
  ];
  return (
    abi: int.parse(abi.group(1)!),
    sizes: sizes,
    structIds: ids,
    statuses: <String>[
      for (int code = 0; statuses.containsKey(code); code++) statuses[code]!,
    ],
    api: api,
  );
}

String? _pinnedEmsdk(Directory root) {
  final File file = File('${root.path}/$emsdkVersionFile');
  if (!file.existsSync()) {
    return null;
  }
  final String version = file.readAsStringSync().trim();
  return RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version) ? version : null;
}

/// The release in `emcc --version`'s first line, which reads
/// `emcc (Emscripten gcc/clang-like replacement ...) 6.0.11 (<commit>)`.
String? _emccVersion(String? output) {
  if (output == null) {
    return null;
  }
  return RegExp(
    r'^emcc \(.*\) (\d+\.\d+\.\d+)\b',
    multiLine: true,
  ).firstMatch(output)?.group(1);
}

Future<String?> _probeEmcc(Map<String, String> environment) async {
  final String emscripten = '${environment['EMSDK']}/upstream/emscripten';
  final List<String> candidates = Platform.isWindows
      ? <String>['$emscripten/emcc.exe', '$emscripten/emcc.bat']
      : <String>['$emscripten/emcc'];
  for (final String emcc in candidates) {
    if (!File(emcc).existsSync()) {
      continue;
    }
    try {
      final ProcessResult result = await Process.run(
        emcc,
        <String>['--version'],
        environment: environment,
        runInShell: emcc.endsWith('.bat'),
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      return result.exitCode == 0 ? result.stdout as String : null;
    } on ProcessException {
      return null;
    }
  }
  return null;
}

/// [explicit], else the newest Android SDK CMake directory's copy, else the
/// first on PATH.
String? _findTool(
  String name,
  String? explicit,
  Map<String, String> environment,
) {
  if (explicit != null && explicit.isNotEmpty) {
    return explicit;
  }
  final String executable = Platform.isWindows ? '$name.exe' : name;
  final List<String> sdks = <String>[
    ?environment['ANDROID_HOME'],
    ?environment['ANDROID_SDK_ROOT'],
    if (environment['LOCALAPPDATA'] case final String local)
      '$local/Android/Sdk',
    if (environment['HOME'] case final String home) '$home/Android/Sdk',
  ];
  for (final String sdk in sdks) {
    final Directory cmakes = Directory('$sdk/cmake');
    if (!cmakes.existsSync()) {
      continue;
    }
    final List<String> versions =
        cmakes
            .listSync()
            .whereType<Directory>()
            .map((Directory d) => d.path)
            .toList()
          ..sort();
    for (final String version in versions.reversed) {
      if (File('$version/bin/$executable').existsSync()) {
        return '$version/bin/$executable';
      }
    }
  }
  final String separator = Platform.isWindows ? ';' : ':';
  for (final String dir in (environment['PATH'] ?? '').split(separator)) {
    if (dir.isNotEmpty && File('$dir/$executable').existsSync()) {
      return '$dir/$executable';
    }
  }
  return null;
}

Future<int> _run(
  String executable,
  List<String> args,
  Directory root,
  Map<String, String> environment,
) async {
  try {
    final Process process = await Process.start(
      executable,
      args,
      workingDirectory: root.path,
      environment: environment,
      mode: ProcessStartMode.inheritStdio,
    );
    return await process.exitCode;
  } on ProcessException {
    return 127;
  }
}

/// SHA-256 of [path] under [root]. Text is hashed with LF line ends, so a
/// CRLF checkout matches the record; `.wasm` is hashed as it is.
String _digest(Directory root, String path) {
  final File file = File('${root.path}/$path');
  if (path.endsWith('.wasm')) {
    return sha256.convert(file.readAsBytesSync()).toString();
  }
  return sha256.convert(utf8.encode(_lf(file.readAsStringSync()))).toString();
}

String _lf(String text) => text.replaceAll('\r\n', '\n');

Map<String, Object?>? _json(Directory root, String path) {
  final File file = File('${root.path}/$path');
  if (!file.existsSync()) {
    return null;
  }
  try {
    final Object? decoded = jsonDecode(file.readAsStringSync());
    return decoded is Map<String, Object?> ? decoded : null;
  } on FormatException {
    return null;
  }
}

Map<String, Object?> _map(Object? value) =>
    value is Map<String, Object?> ? value : <String, Object?>{};

String _relative(Directory root, String path) {
  final String base = root.absolute.path.replaceAll(r'\', '/');
  final String full = File(path).absolute.path.replaceAll(r'\', '/');
  return full.startsWith('$base/') ? full.substring(base.length + 1) : full;
}

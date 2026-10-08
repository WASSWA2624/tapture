@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/whisper_wasm.dart';
import 'support/plan_fixture.dart' show dartExecutable;

/// A miniature frontend tree: a header, an export list, a vendor record,
/// stand-in artifacts and a worker with both tables (dev-plan task 111).
const String _fixture = 'test/tool/fixtures/whisper_wasm';

const String _package = 'packages/tapture_whisper';
const String _shim = '$_package/src/tapture_whisper.cpp';
const String _wasm = 'web/whisper/tapture_whisper_mt.wasm';
const String _worker = 'web/whisper/whisper_worker.js';

/// What the fixture records as each variant's link flags.
const Map<String, String> _flags = <String, String>{
  'st': '-O3 -msimd128',
  'mt': '-O3 -msimd128 -pthread',
};

void main() {
  group('the shipped engine', () {
    test('passes --check, run as CI runs it', () async {
      final ProcessResult result = await Process.run(
        dartExecutable(),
        <String>[
          'run',
          '--verbosity=error',
          'tool/whisper_wasm.dart',
          '--check',
        ],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('whisper wasm: clean'));
      expect(result.exitCode, 0);
    });

    test('records both variants built with the pinned emsdk', () {
      final Map<String, Object?> record =
          jsonDecode(File(whisperWasmRecord).readAsStringSync())
              as Map<String, Object?>;
      final String pinned = File(emsdkVersionFile).readAsStringSync().trim();
      final Map<String, Object?> flags =
          record['flags']! as Map<String, Object?>;
      final Map<String, Object?> files =
          record['files']! as Map<String, Object?>;

      expect(pinned, '6.0.11');
      expect(record['emsdk'], pinned);
      expect(record['abi'], 1);
      expect(record['commit'], '927cfce34f31707e17f2bff35c349632fb9e2c3a');
      expect(files.keys, unorderedEquals(whisperWasmOutputs));
      expect(flags['st'], isNot(contains('-pthread')));
      expect(
        flags['mt'],
        allOf(
          contains('-pthread'),
          contains('-sPTHREAD_POOL_SIZE=8'),
          contains('-sPTHREAD_POOL_SIZE_STRICT=2'),
        ),
      );
      for (final Object? variant in flags.values) {
        expect(
          variant,
          allOf(
            contains('-sENVIRONMENT=worker,node'),
            contains('-sEXPORTED_FUNCTIONS=@src/wasm_exports.txt'),
            contains('HEAP64'),
            contains('HEAPU32'),
          ),
        );
      }
    });
  });

  group('--check on the fixture', () {
    late Directory root;

    setUp(() {
      root = _copyFixture();
      writeWhisperWasmRecord(root, emsdk: '6.0.11', flags: _flags);
    });

    test('passes on the tree it was recorded from', () async {
      final ({int code, String problems}) run = await _check(root);

      expect(run.problems, isEmpty);
      expect(run.code, 0);
    });

    test('records the shim and vendored sources, not the samples or the '
        'native smoke tool', () {
      expect(
        whisperWasmInputs(root),
        containsAll(<String>[
          _shim,
          '$_package/src/wasm_exports.txt',
          '$_package/src/generated/ggml-version.h',
          '$_package/third_party/whisper.cpp/src/whisper.cpp',
          '$_package/VENDOR.json',
          emsdkVersionFile,
        ]),
      );
      expect(
        whisperWasmInputs(root),
        isNot(
          anyOf(
            contains('$_package/src/smoke/tw_smoke.c'),
            contains('$_package/third_party/whisper.cpp/samples/jfk.wav'),
          ),
        ),
      );
    });

    test('a changed shim input is reported with exit 1', () async {
      File(
        '${root.path}/$_shim',
      ).writeAsStringSync('int tw_fixture_shim(void) { return 2; }\n');

      final ({int code, String problems}) run = await _check(root);

      expect(run.code, 1);
      expect(run.problems, contains('$_shim:1: sha256 '));
      expect(run.problems, contains('rebuild with --build'));
    });

    test('a tampered .wasm is reported with exit 1', () async {
      final File wasm = File('${root.path}/$_wasm');
      wasm.writeAsBytesSync(<int>[...wasm.readAsBytesSync(), 0]);

      final ({int code, String problems}) run = await _check(root);

      expect(run.code, 1);
      expect(run.problems, contains('$_wasm:1: sha256 '));
      expect(run.problems, contains('changed after the build'));
    });

    test('a worker struct-table drift is reported with exit 1', () async {
      _edit(
        root,
        _worker,
        'SPAN: { id: 2, size: 16 }',
        'SPAN: { id: 2, size: 24 }',
      );

      final ({int code, String problems}) run = await _check(root);

      expect(run.code, 1);
      expect(
        run.problems,
        contains(
          '$_worker:5: SPAN size 24; $_package/src/tapture_whisper.h has '
          'TW_SIZEOF_SPAN 16',
        ),
      );
    });

    test('a struct id drift and a missing struct row are reported', () async {
      _edit(root, _worker, '  CONTEXT_OPTIONS: { id: 1, size: 16 },\n', '');
      _edit(root, _worker, 'SPAN: { id: 2,', 'SPAN: { id: 3,');

      final ({int code, String problems}) run = await _check(root);

      expect(run.code, 1);
      expect(run.problems, contains('SPAN id 3;'));
      expect(
        run.problems,
        contains(
          'CONTEXT_OPTIONS (TW_SIZEOF_CONTEXT_OPTIONS) '
          'is missing from the struct table',
        ),
      );
    });

    test('a status-table drift is reported', () async {
      _edit(root, _worker, "  'model_mismatch',\n", '');

      final ({int code, String problems}) run = await _check(root);

      expect(run.code, 1);
      expect(run.problems, contains('status 2 (model_mismatch) is missing'));
    });

    test(
      'an export list or glue that differs from TW_API is reported',
      () async {
        _edit(
          root,
          '$_package/src/wasm_exports.txt',
          '_tw_version\n',
          '_tw_extra\n',
        );
        _edit(
          root,
          'web/whisper/tapture_whisper_st.js',
          'Module["_tw_abi_version"]',
          'Module["_tw_abi"]',
        );
        writeWhisperWasmRecord(root, emsdk: '6.0.11', flags: _flags);

        final ({int code, String problems}) run = await _check(root);

        expect(run.code, 1);
        expect(
          run.problems,
          allOf(
            contains('wasm_exports.txt:3: _tw_extra is not a TW_API name'),
            contains('_tw_version, a TW_API name of'),
            contains(
              'tapture_whisper_st.js:1: does not export _tw_abi_version',
            ),
          ),
        );
      },
    );

    test('reports every violation in one run', () async {
      File('${root.path}/$_shim').writeAsStringSync('changed\n');
      File('${root.path}/$_wasm').writeAsBytesSync(<int>[0, 1, 2]);
      _edit(root, _worker, 'size: 16 },\n});', 'size: 8 },\n});');
      File('${root.path}/$emsdkVersionFile').writeAsStringSync('6.0.12\n');

      final ({int code, String problems}) run = await _check(root);

      expect(run.code, 1);
      expect(
        run.problems,
        allOf(
          contains('$_shim:1:'),
          contains('$_wasm:1:'),
          contains('$_worker:5:'),
          contains('emsdk 6.0.11;'),
          contains('$emsdkVersionFile:1: sha256'),
        ),
      );
    });

    test('a CRLF checkout of a text input still matches its record', () async {
      final File shim = File('${root.path}/$_shim');
      shim.writeAsStringSync(shim.readAsStringSync().replaceAll('\n', '\r\n'));

      final ({int code, String problems}) run = await _check(root);

      expect(run.problems, isEmpty);
      expect(run.code, 0);
    });
  });

  group('--build', () {
    test(
      'refuses an emcc that is not the pinned release, before building',
      () async {
        final Directory root = _copyFixture();
        final StringBuffer problems = StringBuffer();

        final int code = await runWhisperWasm(
          <String>['--build'],
          root: root,
          environment: <String, String>{'EMSDK': '${root.path}/emsdk'},
          emccVersion: (Map<String, String> environment) async =>
              'emcc (Emscripten gcc/clang-like replacement + linker emulating '
              'GNU ld) 6.0.10 (0123456789abcdef)\n',
          problems: problems,
          progress: StringBuffer(),
        );

        expect(code, 1);
        expect(
          problems.toString(),
          contains(
            '$emsdkVersionFile:1: emcc is 6.0.10, not the pinned 6.0.11',
          ),
        );
        expect(File('${root.path}/$whisperWasmRecord').existsSync(), isFalse);
        expect(Directory('${root.path}/build').existsSync(), isFalse);
      },
    );

    test('refuses to run without an activated emsdk', () async {
      final Directory root = _copyFixture();
      final StringBuffer problems = StringBuffer();
      bool probed = false;

      final int code = await runWhisperWasm(
        <String>['--build'],
        root: root,
        environment: <String, String>{},
        emccVersion: (Map<String, String> environment) async {
          probed = true;
          return null;
        },
        problems: problems,
        progress: StringBuffer(),
      );

      expect(code, 1);
      expect(probed, isFalse);
      expect(problems.toString(), contains('EMSDK is not set'));
    });
  });

  test('bad arguments print the usage and exit 64', () async {
    for (final List<String> args in <List<String>>[
      <String>[],
      <String>['--check', '--smoke'],
      <String>['--build', '--check'],
      <String>['--check', '--check'],
      <String>['--fast'],
    ]) {
      final StringBuffer problems = StringBuffer();

      final int code = await runWhisperWasm(
        args,
        root: _copyFixture(),
        problems: problems,
        progress: StringBuffer(),
      );

      expect(code, 64, reason: '$args');
      expect(problems.toString(), contains('usage:'));
    }
  });
}

Future<({int code, String problems})> _check(Directory root) async {
  final StringBuffer problems = StringBuffer();
  final int code = await runWhisperWasm(
    <String>['--check'],
    root: root,
    problems: problems,
    progress: StringBuffer(),
  );
  return (code: code, problems: problems.toString());
}

void _edit(Directory root, String path, String from, String to) {
  final File file = File('${root.path}/$path');
  final String text = file.readAsStringSync();
  expect(text, contains(from), reason: path);
  file.writeAsStringSync(text.replaceFirst(from, to));
}

Directory _copyFixture() {
  final Directory root = Directory.systemTemp.createTempSync(
    'tapture_whisper_wasm_',
  );
  addTearDown(() => root.deleteSync(recursive: true));
  final Directory source = Directory(_fixture);
  for (final FileSystemEntity entity in source.listSync(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final String relative = entity.path
        .replaceAll(r'\', '/')
        .substring(source.path.length + 1);
    File('${root.path}/$relative')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(entity.readAsBytesSync());
  }
  return root;
}

@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/whisper_vendor.dart';

/// A miniature upstream, its one patch and its source list
/// (dev-plan task 102).
const String _fixture = 'test/tool/fixtures/whisper_vendor';

/// The fixture upstream's KEEP list: everything but its README and CMake.
const List<String> _keep = <String>[
  'LICENSE',
  'include/whisper.h',
  'ggml/include/ggml.h',
  'ggml/src/ggml.c',
  'ggml/src/ggml-cpu/arch/x86/quants.c',
  'ggml/src/ggml-cpu/arch/arm/quants.c',
  'src/whisper.cpp',
];

const String _package = 'packages/tapture_whisper';
const String _vendored = '$_package/third_party/whisper.cpp';
const String _patch = '$_package/third_party/patches/0001-fixture-abort.patch';
const String _forwarders =
    '$_package/darwin/tapture_whisper/Sources/'
    'tapture_whisper';
const String _podspec = '$_package/darwin/tapture_whisper.podspec';
const String _swiftPackage = '$_package/darwin/tapture_whisper/Package.swift';

/// What only the Apple manifests add to the CMake definitions: Accelerate,
/// for vDSP only, with the two definitions upstream
/// `ggml/src/ggml-cpu/CMakeLists.txt:67-69` pairs with it (design §2.4).
const List<String> _appleOnly = <String>[
  'GGML_USE_ACCELERATE',
  'ACCELERATE_NEW_LAPACK',
  'ACCELERATE_LAPACK_ILP64',
];

/// Settings no Apple build may carry: AVX (macOS x86_64 links at launch on
/// pre-AVX2 Macs), Metal, CoreML, BLAS, OpenMP and per-CPU targets.
final RegExp _forbidden = RegExp(
  r'[-\w]*(?:avx|metal|coreml|blas|openmp)[-\w]*|-m(?:arch|cpu|tune)=\S*',
  caseSensitive: false,
);

void main() {
  group('the shipped tree', () {
    test('passes --check, run as the build runs it', () async {
      final ProcessResult result = await Process.run(
        _dartExecutable(),
        <String>[
          'run',
          '--verbosity=error',
          'tool/whisper_vendor.dart',
          '--check',
        ],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      expect(result.stderr, isEmpty);
      expect(result.stdout, contains('whisper vendor: clean'));
      expect(result.exitCode, 0);
    });

    test('holds exactly the KEEP list, with patch 0001 recorded', () {
      final Object? record = jsonDecode(
        File('$_package/VENDOR.json').readAsStringSync(),
      );
      expect(record, isA<Map<String, Object?>>());
      final Map<String, Object?> fields = record! as Map<String, Object?>;
      final Map<String, Object?> files =
          fields['files']! as Map<String, Object?>;
      expect(files.keys.toSet(), upstreamWhisperPin.keep.toSet());
      final List<Object?> patches = fields['patches']! as List<Object?>;
      expect(patches, hasLength(1));
      final Map<String, Object?> patch =
          patches.single! as Map<String, Object?>;
      expect(patch['name'], '0001-sched-abort-callback.patch');
      final Map<String, Object?> touched =
          patch['files']! as Map<String, Object?>;
      final Map<String, Object?> whisper =
          touched['src/whisper.cpp']! as Map<String, Object?>;
      expect(whisper['upstreamSha256'], isA<String>());
      expect(whisper['patchedSha256'], isA<String>());
      expect(whisper['upstreamSha256'], isNot(whisper['patchedSha256']));
      expect(fields['tarballSha256'], upstreamWhisperPin.tarballSha256);
    });
  });

  group('--from', () {
    test('extracts only the KEEP list, patches it and records it', () {
      final Directory root = _frontend();
      final File tarball = _tarball();
      final List<String> problems = vendorWhisper(
        root,
        tarball,
        pin: _pin(tarball),
      );

      expect(problems, isEmpty);
      final List<String> vendored = <String>[
        for (final FileSystemEntity entity in Directory(
          '${root.path}/$_vendored',
        ).listSync(recursive: true))
          if (entity is File)
            entity.path
                .replaceAll(r'\', '/')
                .substring('${root.path}/$_vendored/'.length),
      ];
      expect(vendored.toSet(), _keep.toSet());
      expect(
        File('${root.path}/$_vendored/src/whisper.cpp').readAsStringSync(),
        contains('compute(4, false)'),
      );
      final String record = File(
        '${root.path}/$_package/VENDOR.json',
      ).readAsStringSync();
      expect(record, contains('"name": "0001-fixture-abort.patch"'));
      expect(record, contains('"upstreamSha256"'));
      expect(record, contains('"patchedSha256"'));
      expect(
        File(
          '${root.path}/$_forwarders/tw_cpu__arch_quants_c.c',
        ).readAsStringSync(),
        allOf(
          contains('#if defined(__aarch64__)'),
          contains('#elif defined(__x86_64__)'),
        ),
      );
    });

    test('refuses a tarball that is not the pinned one, writing nothing', () {
      final Directory root = _frontend();
      final File tarball = _tarball();
      final List<String> problems = vendorWhisper(
        root,
        tarball,
        pin: (
          tag: 'v0.0.0',
          commit: '0' * 40,
          tarballSha256: '0' * 64,
          keep: _keep,
        ),
      );

      expect(problems, hasLength(1));
      expect(problems.single, contains(':0: sha256 '));
      expect(File('${root.path}/$_package/VENDOR.json').existsSync(), isFalse);
    });

    test('reports a hunk that does not apply at its patch line', () {
      final Directory root = _frontend();
      File('${root.path}/$_patch').writeAsStringSync(
        File(
          '$_fixture/patches/0001-fixture-abort.patch',
        ).readAsStringSync().replaceFirst(
          '-    return compute(4) ? 0 : 1;',
          '-    return compute(8) ? 0 : 1;',
        ),
      );

      final File tarball = _tarball();
      final List<String> problems = vendorWhisper(
        root,
        tarball,
        pin: _pin(tarball),
      );

      expect(problems, <String>[
        '$_patch:13: this hunk does not apply to src/whisper.cpp',
      ]);
      expect(File('${root.path}/$_package/VENDOR.json').existsSync(), isFalse);
    });
  });

  group('--check', () {
    late Directory root;
    late WhisperVendorPin pin;

    setUp(() {
      root = _frontend();
      final File tarball = _tarball();
      pin = _pin(tarball);
      expect(vendorWhisper(root, tarball, pin: pin), isEmpty);
    });

    test('passes on a freshly vendored tree', () {
      final StringBuffer problems = StringBuffer();
      final StringBuffer progress = StringBuffer();

      final int code = runWhisperVendor(
        <String>['--check'],
        root: root,
        pin: pin,
        problems: problems,
        progress: progress,
      );

      expect(problems.toString(), isEmpty);
      expect(progress.toString(), 'whisper vendor: clean\n');
      expect(code, 0);
    });

    test('reports every kind of violation in one run, each at path:line', () {
      File('${root.path}/$_vendored/include/whisper.h').deleteSync();
      File(
        '${root.path}/$_vendored/ggml/src/extra.c',
      ).writeAsStringSync('int extra(void) { return 0; }\n');
      File(
        '${root.path}/$_vendored/ggml/src/ggml.c',
      ).writeAsStringSync('int ggml_fixture(void) { return 2; }\n');
      File('${root.path}/$_patch').writeAsStringSync(
        '${File('${root.path}/$_patch').readAsStringSync()}\n',
      );
      File(
        '${root.path}/$_forwarders/tw_base__ggml_c.c',
      ).writeAsStringSync('#include "elsewhere/ggml.c"\n');
      final StringBuffer problems = StringBuffer();
      final StringBuffer progress = StringBuffer();

      final int code = runWhisperVendor(
        <String>['--check'],
        root: root,
        pin: pin,
        problems: problems,
        progress: progress,
      );

      final List<String> lines = const LineSplitter().convert(
        problems.toString(),
      );
      expect(
        lines,
        containsAll(<Matcher>[
          allOf(
            startsWith('$_package/VENDOR.json:'),
            contains(
              'third_party/whisper.cpp/include/whisper.h is recorded '
              'but missing',
            ),
          ),
          startsWith('$_vendored/ggml/src/extra.c:1: not recorded'),
          allOf(
            startsWith('$_vendored/ggml/src/ggml.c:1: '),
            contains('records'),
          ),
          allOf(
            startsWith('$_patch:1: sha256 '),
            contains('An unrecorded patch change'),
          ),
          startsWith('$_forwarders/tw_base__ggml_c.c:1: stale forwarder'),
        ]),
      );
      for (final String line in lines) {
        expect(line, matches(RegExp(r'^[\w./-]+:\d+: \S')));
      }
      expect(lines, hasLength(5));
      expect(progress.toString(), 'whisper vendor: 5 violation(s)\n');
      expect(code, 1);
    });

    test('reports a source-list entry that is not vendored', () {
      final File sources = File(
        '${root.path}/$_package/src/'
        'whisper_sources.cmake',
      );
      sources.writeAsStringSync(
        sources.readAsStringSync().replaceFirst(
          '  ggml/src/ggml.c\n',
          '  ggml/src/ggml.c\n  ggml/src/ggml-missing.c\n',
        ),
      );

      final List<String> problems = checkWhisperVendor(root, pin: pin);

      expect(
        problems,
        contains(
          '$_package/src/whisper_sources.cmake:4: ggml/src/ggml-missing.c is '
          'not vendored',
        ),
      );
    });

    test('reports a patched file that no longer matches its record', () {
      final File whisper = File('${root.path}/$_vendored/src/whisper.cpp');
      whisper.writeAsStringSync(
        whisper.readAsStringSync().replaceFirst('false', 'true'),
      );

      final List<String> problems = checkWhisperVendor(root, pin: pin);

      expect(
        problems,
        contains(
          allOf(
            startsWith('$_package/VENDOR.json:'),
            contains(
              '0001-fixture-abort.patch records src/whisper.cpp '
              'patched as',
            ),
          ),
        ),
      );
    });
  });

  group('the Darwin forwarders (task 105)', () {
    test('compile every Apple source of the list once, each under a unique '
        'object name', () {
      final Map<String, List<String>> sets = _sourceSets(
        File('$_package/src/whisper_sources.cmake').readAsStringSync(),
      );
      final List<File> units = Directory(
        _forwarders,
      ).listSync().whereType<File>().toList();
      final List<String> names = <String>[
        for (final File unit in units) _fileName(unit.path),
      ];
      final List<String> included = <String>[
        for (final File unit in units)
          for (final Match match in RegExp(
            r'#include "\.\./\.\./\.\./\.\./third_party/whisper\.cpp/([^"]+)"',
          ).allMatches(unit.readAsStringSync()))
            match.group(1)!,
      ];

      expect(
        names.map((String name) => name.split('.').first).toSet(),
        hasLength(names.length),
        reason: 'Xcode names an object after its file, extension dropped',
      );
      expect(included.toSet(), hasLength(included.length));
      expect(included.toSet(), <String>{
        for (final MapEntry<String, List<String>> set in sets.entries)
          if (set.key != 'TW_GGML_CPU_SOURCES_WASM') ...set.value,
      });
      expect(
        names,
        containsAll(<String>[
          'tw_shim__tapture_whisper_cpp.cpp',
          'tw_shim__tw_sha256_c.c',
        ]),
      );
    });

    test('select the arm64 or x86_64 source by the compiler target', () {
      for (final (String unit, String source) in <(String, String)>[
        ('tw_cpu__arch_quants_c.c', 'quants.c'),
        ('tw_cpu__arch_repack_cpp.cpp', 'repack.cpp'),
      ]) {
        const String vendor = '../../../../third_party/whisper.cpp';
        expect(
          _withoutBanner(File('$_forwarders/$unit').readAsStringSync()),
          '#if defined(__aarch64__)\n'
          '#include "$vendor/ggml/src/ggml-cpu/arch/arm/$source"\n'
          '#elif defined(__x86_64__)\n'
          '#include "$vendor/ggml/src/ggml-cpu/arch/x86/$source"\n'
          '#endif\n',
        );
      }
    });

    test('are all generated, and every include resolves in the package', () {
      final List<File> files = Directory(
        _forwarders,
      ).listSync(recursive: true).whereType<File>().toList();
      expect(files, isNotEmpty);
      for (final File file in files) {
        final String text = file.readAsStringSync().replaceAll('\r\n', '\n');
        expect(
          text,
          startsWith('// Generated by frontend/tool/whisper_vendor.dart'),
          reason: file.path,
        );
        final List<String> includes = <String>[
          for (final Match match in RegExp(
            r'#include "([^"]+)"',
          ).allMatches(text))
            match.group(1)!,
        ];
        expect(includes, isNotEmpty, reason: file.path);
        for (final String include in includes) {
          expect(
            File('${file.parent.path}/$include').existsSync(),
            isTrue,
            reason: '${file.path} includes $include',
          );
        }
      }
      expect(
        _withoutBanner(
          File('$_forwarders/include/tapture_whisper.h').readAsStringSync(),
        ),
        '#include "../../../../../src/tapture_whisper.h"\n',
      );
    });
  });

  group('--check on forwarders (task 105)', () {
    late Directory root;
    late WhisperVendorPin pin;

    setUp(() {
      root = _frontend();
      final File tarball = _tarball();
      pin = _pin(tarball);
      expect(vendorWhisper(root, tarball, pin: pin), isEmpty);
    });

    test('reports a stale, a missing and a stray forwarder together', () {
      File(
        '${root.path}/$_forwarders/tw_cpu__arch_quants_c.c',
      ).writeAsStringSync(
        '#include "../../../../third_party/whisper.cpp/'
        'ggml/src/ggml-cpu/arch/x86/quants.c"\n',
      );
      File(
        '${root.path}/$_forwarders/forward/ggml.h',
      ).writeAsStringSync('#pragma once\n');
      File(
        '${root.path}/$_forwarders/tw_whisper__whisper_cpp.cpp',
      ).deleteSync();
      File(
        '${root.path}/$_forwarders/tw_base__stray_c.c',
      ).writeAsStringSync('int stray;\n');
      final StringBuffer problems = StringBuffer();
      final StringBuffer progress = StringBuffer();

      final int code = runWhisperVendor(
        <String>['--check'],
        root: root,
        pin: pin,
        problems: problems,
        progress: progress,
      );

      expect(
        const LineSplitter().convert(problems.toString()),
        unorderedEquals(<String>[
          '$_forwarders/tw_cpu__arch_quants_c.c:1: stale forwarder; it no '
              'longer matches src/whisper_sources.cmake, re-run --from',
          '$_forwarders/tw_whisper__whisper_cpp.cpp:1: forwarder missing; '
              're-run --from',
          '$_forwarders/forward/ggml.h:1: stale forwarder; it no longer '
              'matches src/whisper_sources.cmake, re-run --from',
          '$_forwarders/tw_base__stray_c.c:1: stale forwarder; nothing in '
              'src/whisper_sources.cmake generates it',
        ]),
      );
      expect(progress.toString(), 'whisper vendor: 4 violation(s)\n');
      expect(code, 1);
    });

    test('reports the forwarders a source-list change leaves stale', () {
      final File sources = File(
        '${root.path}/$_package/src/whisper_sources.cmake',
      );
      sources.writeAsStringSync(
        sources.readAsStringSync().replaceFirst(
          'set(TW_GGML_CPU_SOURCES_ARM64\n'
              '  ggml/src/ggml-cpu/arch/arm/quants.c\n'
              ')\n',
          '',
        ),
      );

      final List<String> problems = checkWhisperVendor(root, pin: pin);

      expect(problems, <String>[
        '$_forwarders/tw_cpu__arch_quants_c.c:1: stale forwarder; it no '
            'longer matches src/whisper_sources.cmake, re-run --from',
      ]);
    });
  });

  group('the Apple manifests (task 105)', () {
    late String cmake;
    late String podspec;
    late String swift;

    setUp(() {
      cmake = File('$_package/src/CMakeLists.txt').readAsStringSync();
      podspec = File(_podspec).readAsStringSync();
      swift = File(_swiftPackage).readAsStringSync();
    });

    test('list the defines and flags src/CMakeLists.txt uses for Apple', () {
      expect(
        _appleDrift(cmake: cmake, podspec: podspec, swift: swift),
        isEmpty,
      );

      for (final String manifest in <String>[
        _code(podspec, '#'),
        _code(swift, '//'),
      ]) {
        expect(manifest, contains('-O3'));
        expect(manifest, contains('-fvisibility=hidden'));
        expect(manifest, contains('GGML_USE_ACCELERATE'));
        expect(manifest, contains('NDEBUG'));
        expect(manifest, isNot(contains('-mavx2')));
        expect(manifest, isNot(contains('GGML_AVX2')));
        expect(manifest, isNot(matches(RegExp('metal', caseSensitive: false))));
        expect(
          manifest,
          isNot(matches(RegExp('openmp', caseSensitive: false))),
        );
      }
    });

    test('name the paths the Darwin build reads, and they exist', () {
      expect(
        podspec,
        contains(
          "s.source_files         = 'tapture_whisper/Sources/"
          "tapture_whisper/**/*.{c,cpp,h}'",
        ),
      );
      expect(
        podspec,
        contains(
          r'"${PODS_TARGET_SRCROOT}/tapture_whisper/Sources/tapture_whisper/'
          'forward"',
        ),
      );
      expect(
        podspec,
        contains("s.license          = { :file => '../LICENSE' }"),
      );
      expect(swift, contains('path: "Sources/tapture_whisper"'));
      expect(swift, contains('publicHeadersPath: "include"'));
      expect(File('$_package/LICENSE').existsSync(), isTrue);
      expect(Directory('$_forwarders/forward').existsSync(), isTrue);
      expect(
        File('$_forwarders/include/tapture_whisper.h').existsSync(),
        isTrue,
      );
    });

    test('a manifest that drifts from CMake is reported', () {
      final List<String> drift = _appleDrift(
        cmake: cmake,
        podspec: podspec
            .replaceFirst(' NDEBUG ', ' ')
            .replaceFirst(
              "'OTHER_CFLAGS' => '\$(inherited) -O3",
              "'OTHER_CFLAGS' => '\$(inherited) -O3 -mavx2",
            ),
        swift: swift
            .replaceFirst('("TW_ENGINE", "1")', '("TW_ENGINE", "0")')
            .replaceFirst('type: .dynamic', 'type: .static')
            .replaceFirst(
              '.linkedFramework("Accelerate"),',
              '.linkedFramework("Accelerate"), .linkedFramework("Metal"),',
            ),
      );

      expect(
        drift,
        containsAll(<String>[
          'podspec GCC_PREPROCESSOR_DEFINITIONS: NDEBUG is 1 in CMake, '
              'missing here',
          'podspec OTHER_CFLAGS: [-O3, -mavx2, -ffunction-sections, '
              '-fdata-sections, -w, -fvisibility=hidden], CMake has [-O3, '
              '-ffunction-sections, -fdata-sections, -w, -fvisibility=hidden]',
          'podspec: -mavx2 is forbidden on Apple',
          'Package.swift defines: TW_ENGINE is 1 in CMake, 0 here',
          'Package.swift: not the .dynamic product tapture-whisper',
          'Package.swift: links a framework other than Accelerate',
          'Package.swift: Metal is forbidden on Apple',
        ]),
      );
    });
  });

  test('bad arguments print the usage and exit 64', () {
    final StringBuffer problems = StringBuffer();

    final int code = runWhisperVendor(
      <String>['--frm'],
      root: _frontend(),
      problems: problems,
      progress: StringBuffer(),
    );

    expect(problems.toString(), contains('usage: dart run'));
    expect(code, 64);
  });
}

/// A throwaway `frontend/` holding the fixture's source list and patch in
/// the package, as a repository has them before the first `--from`.
Directory _frontend() {
  final Directory root = Directory.systemTemp.createTempSync(
    'tapture_whisper_vendor_',
  );
  addTearDown(() => root.deleteSync(recursive: true));
  File('${root.path}/$_package/src/whisper_sources.cmake')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(
      File('$_fixture/whisper_sources.cmake').readAsBytesSync(),
    );
  File('${root.path}/$_patch')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(
      File('$_fixture/patches/0001-fixture-abort.patch').readAsBytesSync(),
    );
  return root;
}

/// The fixture upstream packed as a release tarball, under one top folder.
File _tarball() {
  final Directory folder = Directory.systemTemp.createTempSync(
    'tapture_whisper_tarball_',
  );
  addTearDown(() => folder.deleteSync(recursive: true));
  final Archive archive = Archive();
  final String base = Directory(
    '$_fixture/upstream',
  ).absolute.path.replaceAll(r'\', '/');
  final List<File> files =
      Directory(
          '$_fixture/upstream',
        ).listSync(recursive: true).whereType<File>().toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));
  for (final File file in files) {
    final Uint8List bytes = file.readAsBytesSync();
    final String name = file.absolute.path
        .replaceAll(r'\', '/')
        .substring(base.length + 1);
    archive.addFile(ArchiveFile('mini-1.0/$name', bytes.length, bytes));
  }
  final List<int> packed = const GZipEncoder().encode(
    TarEncoder().encode(archive),
  );
  return File('${folder.path}/mini-1.0.tar.gz')..writeAsBytesSync(packed);
}

/// The pin [tarball] satisfies.
WhisperVendorPin _pin(File tarball) => (
  tag: 'v1.0',
  commit: 'f' * 40,
  tarballSha256: sha256.convert(tarball.readAsBytesSync()).toString(),
  keep: _keep,
);

/// The `set(NAME entry ...)` blocks of a `whisper_sources.cmake`.
Map<String, List<String>> _sourceSets(String text) {
  final String code = _code(text, '#');
  return <String, List<String>>{
    for (final Match match in RegExp(
      r'^set\((\w+)\s([^)]*)\)',
      multiLine: true,
    ).allMatches(code))
      match.group(1)!: <String>[
        for (final String entry in match.group(2)!.split(RegExp(r'\s+')))
          if (entry.isNotEmpty) entry,
      ],
  };
}

String _fileName(String path) {
  final String slashed = path.replaceAll(r'\', '/');
  return slashed.substring(slashed.lastIndexOf('/') + 1);
}

/// A generated forwarder without its two-line `//` banner.
String _withoutBanner(String text) {
  String rest = text.replaceAll('\r\n', '\n');
  while (rest.startsWith('//')) {
    rest = rest.substring(rest.indexOf('\n') + 1);
  }
  return rest;
}

/// [text] without its whole-line comments, which start with [marker].
String _code(String text, String marker) => text
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((String line) => !line.trimLeft().startsWith(marker))
    .join('\n');

/// Every way the podspec and `Package.swift` differ from what
/// `src/CMakeLists.txt` compiles for Apple (task 105): the definitions of
/// every target (common, `APPLE` and the shim's, with `TW_ENGINE` on and
/// `TW_REQUIRED_FEATURES` derived from compiler macros instead) plus
/// [_appleOnly]; the non-MSVC `TW_OPT` flags with hidden visibility; the
/// language standards; and no [_forbidden] setting. Empty when they agree.
List<String> _appleDrift({
  required String cmake,
  required String podspec,
  required String swift,
}) {
  final List<String> problems = <String>[];
  List<String> words(String where, String text, RegExp pattern) {
    final Match? match = pattern.firstMatch(text);
    if (match == null) {
      problems.add('$where: nothing matches ${pattern.pattern}');
      return const <String>[];
    }
    return <String>[
      for (final String word in match.group(1)!.trim().split(RegExp(r'\s+')))
        if (word.isNotEmpty && word != r'$(inherited)')
          word.replaceAll(r'\"', '"'),
    ];
  }

  Map<String, String> defines(String where, List<String> list) {
    final Map<String, String> map = <String, String>{
      for (final String define in list)
        define.split('=').first: define.contains('=')
            ? define.substring(define.indexOf('=') + 1)
            : '1',
    };
    if (map.length != list.length) {
      problems.add('$where: a definition is repeated');
    }
    return map;
  }

  void compare(
    String where,
    Map<String, String> actual,
    Map<String, String> expected,
  ) {
    for (final MapEntry<String, String> define in expected.entries) {
      final String? value = actual[define.key];
      if (value == null) {
        problems.add(
          '$where: ${define.key} is ${define.value} in CMake, missing here',
        );
      } else if (value != define.value) {
        problems.add(
          '$where: ${define.key} is ${define.value} in CMake, $value here',
        );
      }
    }
    for (final String name in actual.keys) {
      if (!expected.containsKey(name)) {
        problems.add('$where: $name is not in CMake for Apple');
      }
    }
  }

  void sameFlags(String where, List<String> actual, List<String> expected) {
    if (actual.join(' ') != expected.join(' ')) {
      problems.add('$where: $actual, CMake has $expected');
    }
  }

  List<String> strings(String? text) => <String>[
    for (final Match match in RegExp(
      r'"((?:[^"\\]|\\.)*)"',
    ).allMatches(text ?? ''))
      match.group(1)!,
  ];

  const String cmakeName = 'CMakeLists.txt';
  if (!RegExp(
    r'if\(ANDROID\)\s*set\(TW_OPENMP_DEFAULT ON\)\s*else\(\)\s*'
    r'set\(TW_OPENMP_DEFAULT OFF\)',
  ).hasMatch(cmake)) {
    problems.add('$cmakeName: OpenMP is no longer Android-only');
  }
  final Map<String, String> expected = defines(cmakeName, <String>[
    ...words(cmakeName, cmake, RegExp(r'set\(TW_DEFS\s([^)]*)\)')),
    ...words(
      cmakeName,
      cmake,
      RegExp(r'elseif\(APPLE\)\s*list\(APPEND TW_DEFS\s([^)]*)\)'),
    ),
    for (final String word in words(
      cmakeName,
      cmake,
      RegExp(r'target_compile_definitions\(tapture_whisper PRIVATE\s([^)]*)\)'),
    ))
      if (!word.startsWith(r'${') && !word.startsWith('TW_REQUIRED_FEATURES='))
        word.replaceAll(r'${TW_ENGINE_VALUE}', '1'),
    ..._appleOnly,
  ]);
  final List<String> cFlags = <String>[
    ...words(cmakeName, cmake, RegExp(r'else\(\)\s*set\(TW_OPT\s([^)]*)\)')),
    if (cmake.contains('C_VISIBILITY_PRESET hidden')) '-fvisibility=hidden',
  ];
  final List<String> cxxFlags = <String>[
    ...cFlags,
    if (cmake.contains('VISIBILITY_INLINES_HIDDEN ON'))
      '-fvisibility-inlines-hidden',
  ];
  final String cStandard =
      RegExp(r'\bC_STANDARD (\d+)').firstMatch(cmake)?.group(1) ?? '?';
  final String cxxStandard =
      RegExp(r'\bCXX_STANDARD (\d+)').firstMatch(cmake)?.group(1) ?? '?';

  List<String> podWords(String key) => words(
    'podspec $key',
    podspec,
    RegExp("'${RegExp.escape(key)}' => '([^']*)'"),
  );
  const String podDefinitions = 'podspec GCC_PREPROCESSOR_DEFINITIONS';
  compare(
    podDefinitions,
    defines(podDefinitions, podWords('GCC_PREPROCESSOR_DEFINITIONS')),
    expected,
  );
  sameFlags('podspec OTHER_CFLAGS', podWords('OTHER_CFLAGS'), cFlags);
  sameFlags(
    'podspec OTHER_CPLUSPLUSFLAGS',
    podWords('OTHER_CPLUSPLUSFLAGS'),
    cxxFlags,
  );
  for (final (String key, String value) in <(String, String)>[
    ('GCC_OPTIMIZATION_LEVEL', '3'),
    ('GCC_SYMBOLS_PRIVATE_EXTERN', 'YES'),
    ('GCC_INLINES_ARE_PRIVATE_EXTERN', 'YES'),
    ('GCC_C_LANGUAGE_STANDARD', 'c$cStandard'),
    ('CLANG_CXX_LANGUAGE_STANDARD', 'c++$cxxStandard'),
  ]) {
    final String actual = podWords(key).join(' ');
    if (actual != value) {
      problems.add('podspec $key: $actual, expected $value');
    }
  }
  for (final String line in <String>[
    "s.ios.deployment_target = '13.0'",
    "s.osx.deployment_target = '10.15'",
    "s.frameworks       = 'Accelerate'",
    "s.static_framework = false",
  ]) {
    if (!podspec.contains(line)) {
      problems.add('podspec: no $line');
    }
  }

  const String swiftDefinitions = 'Package.swift defines';
  final String? defineBlock = RegExp(
    r'let defines[^=]*=\s*\[(.*?)\n\]',
    dotAll: true,
  ).firstMatch(swift)?.group(1);
  compare(
    swiftDefinitions,
    defines(swiftDefinitions, <String>[
      for (final Match match in RegExp(
        r'\("(\w+)",\s*(?:nil|"((?:[^"\\]|\\.)*)")\)',
      ).allMatches(defineBlock ?? ''))
        match.group(2) == null
            ? match.group(1)!
            : '${match.group(1)}=${match.group(2)!.replaceAll(r'\"', '"')}',
    ]),
    expected,
  );
  final List<String> swiftC = strings(
    RegExp(
      r'let cFlags: \[String\] = \[([^\]]*)\]',
    ).firstMatch(swift)?.group(1),
  );
  sameFlags('Package.swift cFlags', swiftC, cFlags);
  sameFlags('Package.swift cxxFlags', <String>[
    ...swiftC,
    ...strings(
      RegExp(
        r'let cxxFlags: \[String\] = cFlags \+ \[([^\]]*)\]',
      ).firstMatch(swift)?.group(1),
    ),
  ], cxxFlags);
  for (final (String snippet, String problem) in <(String, String)>[
    (
      '.library(name: "tapture-whisper", type: .dynamic, '
          'targets: ["tapture_whisper"])',
      'not the .dynamic product tapture-whisper',
    ),
    ('.iOS("13.0")', 'not iOS 13'),
    ('.macOS("10.15")', 'not macOS 10.15'),
    ('CSetting.headerSearchPath("forward")', 'C cannot see forward/'),
    ('CXXSetting.headerSearchPath("forward")', 'C++ cannot see forward/'),
    ('CSetting.unsafeFlags(cFlags)', 'C does not use cFlags'),
    ('CXXSetting.unsafeFlags(cxxFlags)', 'C++ does not use cxxFlags'),
    (
      r'defines.map { CSetting.define($0.name, to: $0.value) }',
      'C does not use the defines',
    ),
    (
      r'defines.map { CXXSetting.define($0.name, to: $0.value) }',
      'C++ does not use the defines',
    ),
    ('cLanguageStandard: .c$cStandard', 'not the CMake C standard'),
    ('cxxLanguageStandard: .cxx$cxxStandard', 'not the CMake C++ standard'),
  ]) {
    if (!swift.contains(snippet)) {
      problems.add('Package.swift: $problem');
    }
  }
  final List<String> frameworks = <String>[
    for (final Match match in RegExp(
      r'\.linkedFramework\("([^"]*)"\)',
    ).allMatches(swift))
      match.group(1)!,
  ];
  if (frameworks.join(' ') != 'Accelerate') {
    problems.add('Package.swift: links a framework other than Accelerate');
  }

  for (final (String where, String text) in <(String, String)>[
    ('podspec', _code(podspec, '#')),
    ('Package.swift', _code(swift, '//')),
  ]) {
    for (final String token in <String>{
      for (final Match match in _forbidden.allMatches(text)) match.group(0)!,
    }) {
      problems.add('$where: $token is forbidden on Apple');
    }
  }
  return problems;
}

/// The Dart command line, which is not the executable running this test:
/// `flutter test` runs it inside the Flutter tester.
String _dartExecutable() {
  final String suffix = Platform.isWindows ? '.exe' : '';
  final String running = Platform.resolvedExecutable;
  if (Uri.file(running).pathSegments.last == 'dart$suffix') {
    return running;
  }
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  return flutterRoot == null
      ? 'dart$suffix'
      : '$flutterRoot/bin/cache/dart-sdk/bin/dart$suffix';
}

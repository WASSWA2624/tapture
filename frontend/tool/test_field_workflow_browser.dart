import 'dart:convert';
import 'dart:io';

/// Serves bundled database/browser assets from the unit-test document root.
/// Run from frontend; optional arguments replace the default W14/W15 suites.
Future<void> main(List<String> arguments) async {
  final List<String> testArguments = arguments.isEmpty
      ? <String>[
          'test/features/records/data/managed_recycling_browser_test.dart',
          'test/features/templates/presentation/template_library_flow_test.dart',
          'test/features/records/presentation/recycle_bin_screen_test.dart',
          '--name',
          r'^(?!.*golden).*$',
          '--reporter',
          'expanded',
        ]
      : arguments;
  final File source = File('web/sqlite3.wasm');
  final File workerSource = File('web/drift_worker.js');
  final Directory canvas = Directory('test/canvaskit');
  final Directory fonts = Directory('test/task143-fonts');
  if (!await source.exists() || !await workerSource.exists()) {
    stderr.writeln(
      'Run this command from frontend with the web database assets present.',
    );
    exitCode = 1;
    return;
  }
  final Directory workspace = Directory.current.absolute;
  final String testRoot = await Directory('test').resolveSymbolicLinks();
  final String workspaceRoot = await workspace.resolveSymbolicLinks();
  if (!testRoot.startsWith('$workspaceRoot${Platform.pathSeparator}')) {
    throw StateError('The test document root must stay inside frontend.');
  }
  final Set<String> parents = <String>{testRoot};
  for (final String argument in testArguments) {
    if (!argument.endsWith('_test.dart')) {
      continue;
    }
    final String parent = await File(argument).parent.resolveSymbolicLinks();
    if (parent != testRoot &&
        !parent.startsWith('$testRoot${Platform.pathSeparator}')) {
      throw StateError('Browser suites must stay inside the test root.');
    }
    parents.add(parent);
  }
  // The test iframe has its suite's directory as its document base, so the
  // production database's relative asset URLs need the same files beside it.
  final Map<File, File> databaseAssets = <File, File>{
    for (final String parent in parents) ...<File, File>{
      File('$parent/sqlite3.wasm'): source,
      File('$parent/drift_worker.js'): workerSource,
    },
  };
  final List<FileSystemEntity> targets = <FileSystemEntity>[
    ...databaseAssets.keys,
    canvas,
    fonts,
  ];
  if (targets.any(
    (target) =>
        FileSystemEntity.typeSync(target.path, followLinks: false) !=
        FileSystemEntityType.notFound,
  )) {
    stderr.writeln(
      'A browser fixture already exists under test; preserve or remove it before running.',
    );
    exitCode = 1;
    return;
  }
  final Directory sdk = await _sdkRoot();
  final Directory canvasSource = Directory(
    '${sdk.path}/bin/cache/flutter_web_sdk/canvaskit',
  );
  final Directory fontSource = Directory(
    '${sdk.path}/bin/cache/artifacts/material_fonts',
  );
  final File dart = File(
    '${sdk.path}/bin/cache/dart-sdk/bin/${Platform.isWindows ? 'dart.exe' : 'dart'}',
  );
  final File flutterTool = File('${sdk.path}/bin/cache/flutter_tools.snapshot');
  if (!await dart.exists() || !await flutterTool.exists()) {
    stderr.writeln('Initialize this Flutter SDK before running browser tests.');
    exitCode = 1;
    return;
  }
  final List<FileSystemEntity> owned = <FileSystemEntity>[];
  try {
    for (final MapEntry<File, File> entry in databaseAssets.entries) {
      owned.add(entry.key);
      await entry.value.copy(entry.key.path);
    }
    owned.add(canvas);
    await _copyTree(canvasSource, canvas);
    owned.add(fonts);
    await fonts.create();
    for (final String name in <String>[
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
      'materialicons-regular.otf',
    ]) {
      await File('${fontSource.path}/$name').copy('${fonts.path}/$name');
    }
    final Process tests = await Process.start(
      dart.path,
      <String>[
        '--packages=${sdk.path}/packages/flutter_tools/.dart_tool/package_config.json',
        flutterTool.path,
        'test',
        '--no-pub',
        '--platform',
        'chrome',
        '--concurrency=2',
        ...testArguments,
      ],
      mode: ProcessStartMode.inheritStdio,
      environment: <String, String>{'FLUTTER_ROOT': sdk.path},
    );
    exitCode = await tests.exitCode;
  } finally {
    for (final FileSystemEntity target in owned.reversed) {
      if (FileSystemEntity.typeSync(target.path, followLinks: false) ==
          FileSystemEntityType.notFound) {
        continue;
      }
      final String resolved = await target.resolveSymbolicLinks();
      if (!resolved.startsWith('$testRoot${Platform.pathSeparator}')) {
        throw StateError('Refusing to clean a browser fixture outside test.');
      }
      await target.delete(recursive: target is Directory);
    }
  }
}

Future<Directory> _sdkRoot() async {
  final File config = File('.dart_tool/package_config.json');
  final Map<String, Object?> contents =
      jsonDecode(await config.readAsString()) as Map<String, Object?>;
  final List<Object?> packages = contents['packages']! as List<Object?>;
  final Map<String, Object?> flutter = packages
      .cast<Map<String, Object?>>()
      .singleWhere((package) => package['name'] == 'flutter');
  return Directory.fromUri(
    Directory.fromUri(
      config.absolute.uri.resolve(flutter['rootUri']! as String),
    ).uri.resolve('../../'),
  );
}

Future<void> _copyTree(Directory source, Directory target) async {
  await target.create();
  final Uri sourceUri = source.absolute.uri;
  final Uri targetUri = target.absolute.uri;
  await for (final FileSystemEntity entity in source.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) {
      continue;
    }
    final String relative = entity.absolute.uri.path.substring(
      sourceUri.path.length,
    );
    final File copy = File.fromUri(targetUri.resolve(relative));
    await copy.parent.create(recursive: true);
    await entity.copy(copy.path);
  }
}
